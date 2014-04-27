#!/bin/bash

function get_git_rev()
{
    echo `git ls-remote kde:$repo $branch | cut -f 1`
}

function get_svn_rev()
{
    echo `svn info $branch/$repo | grep "Last Changed Rev: " | cut -f 4 -d ' '`
}

function checkDownloadUptodate()
{
    local isGit="true"
    if [ "$1" = "svn" ]; then
        isGit="false"
    fi
    local finalDestination=$2
    local result=0
    if [ "x$force" != "x-f" ]; then
        if [ -f $finalDestination ]; then
            if [ -f $versionFilePath ]; then
                fileRepoLine=`sed -n '1p' < $versionFilePath`
                if [ "$repoLine" = "$fileRepoLine" ]; then
                    if [ $isGit = "true" ]; then
                        rev=`get_git_rev`
                    else
                        rev=`get_svn_rev`
                    fi
                    fileRev=`sed -n '2p' < $versionFilePath`
                    if [ "$rev" = "$fileRev" ]; then
                        fileSha=`sed -n '3p' < $versionFilePath`
                        realFileSha=`sha256sum $finalDestination`
                        if [ "$fileSha" = "$realFileSha" ]; then
                            result=1
                        fi
                    fi
                fi
            fi
        fi
    fi
    return $result
}

function findCheckout()
{
    local repo=$1
    cd $srcdir || exit 1
    if [ -d frameworks/$repo ]; then
        echo $srcdir/frameworks/$repo
    elif [ -d kdesupport/$repo ]; then
        echo $srcdir/kdesupport/$repo || exit 2
    elif [ -d $repo ]; then
        echo $srcdir/$repo
    else
        echo "NOT FOUND: $repo" 1>&2
        exit 3
    fi
}

# Usage: grabTranslations $repo $l10n $tagname
# Copy .po files from $l10n (full path) into $repo and git add them, then tag rc with $tagname
function grabTranslations()
{
    local repo=$1
    local l10n=$2
    local tagname=$3

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
