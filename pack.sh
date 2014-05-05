#!/bin/bash

. utils.sh
. config

repo_to_pack=$1
force=$2

if [ -z "$repo_to_pack" ]; then
    echo "No repo given"
    exit
fi

mkdir -p versions

# Determine where in sources/ the tarball should go.
# Output: $destination
function adjustDestination() {
    local repo=$1
    metainfo=$srcdir/frameworks/$repo/metainfo.yaml
    if [ -f $metainfo ]; then
        portingAid=`readYamlEntry $metainfo portingAid`
        if [ "$portingAid" = "true" ]; then
            destination=$destination/portingAids
        fi
    fi
}

function determineVersion() {
  . version
  versionFilePath=$PWD/versions/$repo_to_pack
  tarFile=$repo_to_pack-$version.tar.xz
  destination=sources
  adjustDestination $repo
  mkdir -p $destination
  echo $destination/$tarFile
}

cat modules.git | while read repo branch; do
    if [ "$repo_to_pack" = "$repo" ]; then
        repoLine="$repo $branch"

        determineVersion
        checkDownloadUptodate "git" "$destination/$tarFile"
        uptodate=$?
        if [ $uptodate = 1 ]; then
            echo "$repo is already up to date, no need to re-download. Use -f as second parameter if you want to force"
            break;
        fi

        checkout=1
        echo "$repoLine"
        echo "$repoLine" > $versionFilePath

        basename=$repo-$version
        tagname="v$version-$tagsuffix"

        if [ "$release_l10n_separately" = "0" ]; then
            # We must have run make_rc_tag.sh first
            branch=$tagname
        fi

        while [ $checkout -eq 1 ]; do
            rev=`get_git_rev`
            oldpwd=$PWD
            cd $destination
            git archive --remote=kde:$repo $tagname --prefix $basename/ | tar x
            errorcode=$PIPESTATUS # grab error code from git archive
            if [ $errorcode -eq 0 ]; then
                rev2=`get_git_rev`
                if [ $rev = $rev2 ]; then
                    checkout=0
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
                echo "git archive --remote=kde:$repo $tagname --prefix $basename/ failed with error code $errorcode"
            fi
            cd $oldpwd
        done
        echo "$rev"
        echo "$rev" >> $versionFilePath
        sha256sum $destination/$tarFile >> $versionFilePath
    fi
done

cat modules.svn | while read repo branch; do
    if [ $repo_to_pack = $repo ]; then
        repoLine="$repo $branch"

        determineVersion
        checkDownloadUptodate "svn" "sources/$tarFile"
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
