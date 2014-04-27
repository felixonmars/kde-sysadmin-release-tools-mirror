#!/bin/bash

. utils.sh
. config

repo_to_pack=$1
force=$2

if [ -z "$repo_to_pack" ]; then
    echo "No repo given"
    exit
fi

unset CDPATH

mkdir -p versions

# Usage: grabTranslations $repo $l10n $tagname
# Copy .po files from $l10n (full path) into $repo and git add them, then tag rc with $tagname
function grabTranslations()
{
    local repo=$1
    local l10n=$2
    local tagname=v$3

    local cmd=
    if [ "$dry_run" = "1" ]; then
        cmd=echo
    fi

    # Go to the local checkout
    local checkout=$(findCheckout $repo)
    test -d $checkout || exit 1
    local oldpwd=$PWD
    cd $checkout
    mkdir -p po
    git fetch || exit 2
    local status=`git status --porcelain --untracked-files=no`
    if [ -n "$status" ]; then
        echo "$checkout doesn't seem clean:"
        echo "$status"
        exit 2
    fi

    # Copy po files and translated docbooks
    has_po=0
    local subdir
    for subdir in $l10n/*; do
        local lang=`basename $subdir`
        local destdir=$checkout/po/$lang
        local podir=$subdir/messages/$l10n_module
        if test -d $podir; then
            mkdir -p $destdir
            if cp -f $podir/${repo}5.po $destdir 2>/dev/null || cp -f $podir/${repo}5_*.po $destdir 2>/dev/null; then
                has_po=1
            fi
        fi
        # the subdir in l10n is supposed to be named exactly after the framework
        local docdir=$subdir/docs/$l10n_module/$repo
        if test -d $docdir; then
            rm -rf $destdir/docs
            mkdir -p $destdir/docs
            cp -a $docdir/* $destdir/docs
            test -f $destdir/docs/CMakeLists.txt && has_po=1
        fi

    done

    if [ $has_po -eq 1 ]; then
        git add po
        git ci po -m "Commit translations from `basename $l10n_repo`"
    fi

    # Tag
    git tag -d $tagname 2>/dev/null
    git tag -a $tagname -m "Create tag for $version"  || exit 4
    $cmd git push --tags || exit 5
    cd $oldpwd
}

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

        if [ "$release_l10n_separately" = "0" ]; then
            grabTranslations "$repo" "$PWD/l10n" "$version-$tagsuffix"
        fi

        while [ $checkout -eq 1 ]; do
            rev=`get_git_rev`
            oldpwd=$PWD
            cd $destination
            git archive --remote=kde:$repo $branch --prefix $basename/ | tar x
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
                echo "git archive --remote=kde:$repo $branch --prefix $basename/ failed with error code $errorcode"
            fi
            cd $oldpwd
        done
        echo "$rev"
        echo "$rev" >> $versionFilePath
        echo PWD=$PWD
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
