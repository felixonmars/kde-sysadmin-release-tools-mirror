#!/bin/bash

. utils.sh
. config

repo_to_pack=$1
force=$2

if [ -z "$repo_to_pack" ]; then
    echo "No repo given"
    exit
fi

mkdir -p sources
mkdir -p versions

function determineVersion() {
  . version
  versionFilePath=$PWD/versions/$repo_to_pack
  tarFile=$repo_to_pack-$version.tar.xz
  echo $tarFile
}

cat modules.git | while read repo branch; do
    if [ "$repo_to_pack" = "$repo" ]; then
        repoLine="$repo $branch"

        determineVersion
        checkDownloadUptodate "git" "sources/$tarFile"
        uptodate=$?
        if [ $uptodate = 1 ]; then
            echo "$repo is already up to date, no need to re-download. Use -f as second parameter if you want to force"
            break;
        fi

        checkout=1
        echo "$repoLine"
        echo "$repoLine" > $versionFilePath
        while [ $checkout -eq 1 ]; do
            rev=`get_git_rev`
            basename=$repo-$version
            cd sources
            git archive --remote=kde:$repo $branch --prefix $basename/ | tar x
            errorcode=$PIPESTATUS # grab error code from git archive
            if [ $errorcode -eq 0 ]; then
                rev2=`get_git_rev`

                if [ $rev = $rev2 ]; then
                    checkout=0
                    # Only for frameworks: grab translations and put them into the tarball
                    if [ -f "$basename/$repo.yaml" ]; then
                        grabTranslations "$basename" "$repo"
                    fi
                    tar c --owner 0 --group 0 --numeric-owner $basename | xz -9 > $tarFile

                    if [ $make_zip -eq 1 ]; then
                      zip -r $basename.zip $basename || exit 1
                    fi

                else
                    # someone made a change meanwhile, retry
                    rm -f $tarFile
                fi
                rm -rf $basename
            else
                echo "git archive --remote=kde:$repo $branch --prefix $basename/ failed with error code $errorcode"
            fi
            cd ..
        done
        echo "$rev"
        echo "$rev" >> $versionFilePath
        sha256sum sources/$tarFile >> $versionFilePath
    fi
done

cat modules.svn | while read repo branch; do
    if [ $repo_to_pack = $repo ]; then
        repoLine="$repo $branch"

        determineVersion
        checkDownloadUptodate "svn" "$tarFile"
        uptodate=$?
        if [ $uptodate = 1 ]; then
            echo "$repo is already up to date, no need to re-download. Use -f as second parameter if you want to force"
            break;
        fi

        checkout=1
        echo "$repoLine"
        echo "$repoLine" > $versionFilePath
        while [ $checkout -eq 1 ]; do
            umask 000
            MANIFEST="`mktemp -t`"
            rev=`get_svn_rev`
            svn export $branch/$repo $repo-$version &> /dev/null
            errorcode=$?
            if [ $errorcode -eq 0 ]; then
                rev2=`get_svn_rev`
                if [ "$rev" = "$rev2" ]; then
                    echo "$rev"
                    echo "$rev" >> $versionFilePath
                    find $repo-$version -type f |sed 's/^\.*\/*//'|sort > MANIFEST
                    tar c --owner 0 --group 0 --numeric-owner --no-recursion --files-from MANIFEST | xz -9 > sources/$tarFile
                    rm -f MANIFEST
                    checkout=0
                    finalDestination="sources/$repo_to_pack-$version.tar.xz"
                    sha256sum $finalDestination >> $versionFilePath
                fi
            else
                echo "svn export $branch/$repo $repo-$version failed with error code $errorcode"
            fi
            rm -fr $repo-$version
        done
    fi
done
