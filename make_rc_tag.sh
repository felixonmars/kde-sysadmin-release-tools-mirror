#!/bin/bash

. utils.sh
. config

repo_to_pack=$1

if [ "$release_l10n_separately" = "1" ]; then
    echo "Only makes sense with bundled translations"
    exit
fi

cmd=
if [ "$dry_run" = "1" ]; then
    cmd=echo
fi

# Usage: grabTranslations $repo $branch $l10n
# Copy .po files from $l10n (full path) into $repo (branch $branch) and git add them into local_release
function grabTranslations()
{
    local repo=$1
    local branch=$2
    local l10n=$3

    mkdir -p po

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
                local scriptdir=$subdir/scripts/$l10n_module
                rm -rf $destdir/scripts
                mkdir $destdir/scripts
                cp -rf $scriptdir/${repo}5 $destdir/scripts/ 2>/dev/null || cp -rf $podir/${repo}5_* $destdir/scripts/ 2>/dev/null || rmdir $destdir/scripts
                rm -rf $destdir/scripts/${repo}5/.svn
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
        # Strip unused strings, to keep things small
        cd po
        for f in */*.po ; do msgattrib --output-file=$f --no-obsolete $f ; done
        cd ..

        $cmd git branch -D local_release
        $cmd git checkout -b local_release
        $cmd git add po
        $cmd git commit po -m "Commit translations from `basename $l10n_repo`"
    fi

    if [ `ls po | wc -l` -eq 0 ]; then rm -r po ; fi
}

function tagModule()
{
    local repo=$1
    local version=$2
    local basetag="v$version-rc"

    # Determine first available tag name
    local i=1
    while [ -f ".git/refs/tags/$basetag$i" ]; do
      i=$((i+1))
    done
    local tagname=$basetag$i

    # Tag the current directory with $tagname
    $cmd git tag -a $tagname -m "Create tag for $version"  || exit 4
    $cmd git push origin tag $tagname || exit 5

    # Tell pack.sh which tag to use
    [ -f $oldpwd/tags.git ] && sed -i "/^$repo /d" $oldpwd/tags.git
    echo "$repo $tagname" >> $oldpwd/tags.git

    return 0
}

cat modules.git | while read repo branch; do
    if [ -z "$repo_to_pack" -o "$repo_to_pack" = "$repo" ]; then

        echo $repo

        . version

        basename=$repo-$version

        oldpwd=$PWD
        # Go to the local checkout, ensure clean, update
        checkout=$(findCheckout $repo)
        test -d $checkout || exit 1
        cd $checkout
        status=`git status --porcelain --untracked-files=no`
        if [ -n "$status" ]; then
            echo "$checkout doesn't seem clean:"
            echo "$status"
            exit 2
        fi
        git checkout $branch || exit 2
        git pull || exit 3

        grabTranslations "$repo" "$branch" "$oldpwd/l10n"

        tagModule "$repo" "$version"

        $cmd git checkout $branch

        cd $oldpwd
    fi
done

