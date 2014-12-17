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

    pofiles=`find . -name Messages.sh | xargs grep -- '-o \$podir' | sed -e 's,.*podir/,,' | sed -e 's/pot$/po/'`

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
        rm -rf $destdir/docs
        local podir=$subdir/messages/$l10n_module
        if test -d $podir; then
            local hasdestdir=0;
            test -d $destdir && hasdestdir=1 || mkdir -p $destdir
            for pofile in $pofiles; do
                if [ -f "$podir/$pofile" ] && cp -f "$podir/$pofile" $destdir; then
                    has_po=1
                fi
            done

            if [ "$has_po" -eq 1 ]; then
                # Copy kf5_entry.desktop into kconfigwidgets
                if [ ${repo} = "kconfigwidgets" ]; then
                    local entryfile=$podir/kf5_entry.desktop
                    if [ -f $entryfile ]; then
                        cp -f $entryfile $destdir
                    fi
                fi
                # Copy the scripts subdir
                local scriptdir=$subdir/scripts/$l10n_module
                rm -rf $destdir/scripts
                for pofile in $pofiles; do
                    scriptmod=`echo $pofile | sed 's/\.po$//'`
                    if test -d $scriptdir/$scriptmod; then
                        test -d $destdir/scripts || mkdir $destdir/scripts
                        cp -rf $scriptdir/$scriptmod $destdir/scripts/ 2>/dev/null
                        rm -rf $destdir/scripts/$scriptmod/.svn
                   fi
                done
            elif [ $hasdestdir -eq 0 ]; then
                rm -r $destdir
            fi
        fi
        # Look for translated docbooks
        local docdir=$subdir/docs/$l10n_module
        #  We look at the sources to find out the name of the docbooks we want for this framework

        local docsubdir_it
        for docsubdir_it in $checkout/docs/*; do
            if test -d $docsubdir_it; then
                local docsubdir=`basename $docsubdir_it`
                if test -d $docdir/$docsubdir; then
                    mkdir -p $destdir/docs
                    cp -a $docdir/$docsubdir $destdir/docs/
                    rm -rf $destdir/docs/$docsubdir/.svn
                    has_po=1
                 fi
            fi
        done
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

