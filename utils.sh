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

function grabTranslations()
{
    local basename=$1
    mkdir $basename/po
    local repo=$2
    local subdir
    for subdir in ../l10n/*; do
        local podir=$subdir/messages/$l10n_module
        if test -d $podir; then
            local lang=`basename $subdir`
            cp $podir/${repo}5.po $basename/po/$lang.po 2>/dev/null
            cp $podir/${repo}5_*.po $basename/po/$lang.po 2>/dev/null
        fi
    done
}
