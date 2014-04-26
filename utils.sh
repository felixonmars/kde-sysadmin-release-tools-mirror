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

# grabTranslations $repo $l10n
# Copy .po files from $l10n (full path) into $repo and git add them
function grabTranslations()
{
    local repo=$1
    local l10n=$2
    local checkout=$(findCheckout $repo)
    test -d $checkout || exit 1
    local oldpwd=$PWD

    mkdir -p $checkout/po
    cd $checkout
    local status=`git status --porcelain --untracked-files=no`
    if [ -n "$status" ]; then
        echo "$checkout doesn't seem clean:"
        echo "$status"
        exit 2
    fi
    local subdir
    for subdir in $l10n/*; do
        local podir=$subdir/messages/$l10n_module
        if test -d $podir; then
            local lang=`basename $subdir`
            local pofile=$checkout/po/$lang.po
            cp $podir/${repo}5.po $pofile 2>/dev/null
            cp $podir/${repo}5_*.po $pofile 2>/dev/null
            if [ -f $pofile ]; then
                git add po/$lang.po
            fi
        fi
    done
    git commit po -m "Commit translations copied from `basename $l10n_repo`"
    if [ "$dry_run" = "0" ]; then
        git push
    fi
    cd $oldpwd
}
