#!/bin/bash

function get_git_rev()
{
    echo `git ls-remote kde:$repo $branch | cut -f 1`
}

function get_svn_rev()
{
    echo `svn info $branch/$repo | grep "Last Changed Rev: " | cut -f 2 -d ' '`
}

function checkDownloadUptodate()
{
    isGit="true"
    if [ "$1" = "svn" ]; then
        isGit="false"
    fi
    result=0
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
