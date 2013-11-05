#!/bin/bash

. version
. utils.sh

repo_to_pack=$1
force=$2

if [ -z "$repo_to_pack" ]; then
    echo "No repo given"
    exit
fi

mkdir -p sources
mkdir -p versions

finalDestination="sources/$repo_to_pack-$version.tar.xz"
versionFilePath=versions/$repo_to_pack
tarFile=$repo_to_pack-$version.tar

cat modules.git | while read repo branch; do
    if [ $repo_to_pack = $repo ]; then
        repoLine="$repo $branch"

        checkDownloadUptodate "git"
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
            git archive --remote=kde:$repo $branch --prefix $repo-$version/ > $tarFile
            rev2=`get_git_rev`
            if [ $rev = $rev2 ]; then
                echo "$rev"
                echo "$rev" >> $versionFilePath
                xz -9 $tarFile
                mv $tarFile.xz sources
                sha256sum $finalDestination >> $versionFilePath
                checkout=0
            else
                rm -f $tarFile
            fi
        done
    fi
done

cat modules.svn | while read repo branch; do
    if [ $repo_to_pack = $repo ]; then
        repoLine="$repo $branch"

        checkDownloadUptodate "svn"
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
            rev2=`get_svn_rev`
            if [ "$rev" = "$rev2" ]; then
                echo "$rev"
                echo "$rev" >> $versionFilePath
                find $repo-$version -type f |sed 's/^\.*\/*//'|sort > MANIFEST
                tar cf $tarFile --owner 0 --group 0 --numeric-owner --no-recursion --files-from MANIFEST
                xz -9 $tarFile
                mv $tarFile.xz sources
                rm -f MANIFEST
                checkout=0
                sha256sum $finalDestination >> $versionFilePath
            fi
            rm -fr $repo-$version
        done
    fi
done
