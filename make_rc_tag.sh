#!/bin/bash

. utils.sh
. config

repo_to_pack=$1

if [ "$release_l10n_separately" = "1" ]; then
    echo "Only makes sense with bundled translations"
    exit
fi

# Usage: grabTranslations $repo $branch $l10n $tagname
# Copy .po files from $l10n (full path) into $repo (branch $branch) and git add them, then tag rc with $tagname
function grabTranslations()
{
    local repo=$1
    local branch=$2
    local l10n=$3
    local tagname=$4

    local cmd=
    if [ "$dry_run" = "1" ]; then
        cmd=echo
    fi

    # Go to the local checkout
    local checkout=$(findCheckout $repo)
    test -d $checkout || exit 1
    local oldpwd=$PWD
    cd $checkout
    git checkout $branch
    mkdir -p po
    git fetch || exit 2
    local status=`git status --porcelain --untracked-files=no`
    if [ -n "$status" ]; then
        echo "$checkout doesn't seem clean:"
        echo "$status"
        exit 2
    fi

    if [ -f ".git/refs/tags/$tagname" ]; then
        echo "$checkout appears to have a $tagname tag already, skipping"
        return
    fi

    # Copy po files and translated docbooks
    has_po=0
    local subdir
    for subdir in $l10n/*; do
        local lang=`basename $subdir`
        if [ "$lang" = "x-test" ]; then
            continue
        fi
        local destdir=$checkout/po/$lang
        local podir=$subdir/messages/$l10n_module
        if test -d $podir; then
            local hasdestdir=0;
            test -d $destdir && hasdestdir=1 || mkdir -p $destdir
            if cp -f $podir/${repo}5.po $destdir 2>/dev/null || cp -f $podir/${repo}5_*.po $destdir 2>/dev/null; then
                has_po=1
            elif [ $hasdestdir -eq 0 ]; then
                rm -r $destdir
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
        $cmd git branch -D local_release
        $cmd git checkout -b local_release
        $cmd git add po
        $cmd git ci po -m "Commit translations from `basename $l10n_repo`"
    fi

    if [ `ls po | wc -l` -eq 0 ]; then rm -r po ; fi

    # Tag
    $cmd git tag -a $tagname -m "Create tag for $version"  || exit 4
    $cmd git push origin tag $tagname || exit 5
    if [ $has_po -eq 1 ]; then
        $cmd git checkout $branch
    fi
    cd $oldpwd
}

cat modules.git | while read repo branch; do
    if [ -z "$repo_to_pack" -o "$repo_to_pack" = "$repo" ]; then

        . version

        basename=$repo-$version
        tagname="v$version-$tagsuffix"

        grabTranslations "$repo" "$branch" "$PWD/l10n" "$tagname"
    fi
done

