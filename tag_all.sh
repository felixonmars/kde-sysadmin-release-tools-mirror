#!/bin/bash

unset CDPATH

here=$PWD

. config
. utils.sh

if [ ! -d $srcdir ]; then
    echo "$srcdir does not exist, please fix srcdir variable"
    exit
fi

cat $here/modules.git | while read repo branch; do
    echo $repo
    . $here/version
    tagname=v$version
    versionfile=$here/versions/$repo
    if [ ! -f $versionfile ]; then echo "$versionfile not found"; exit 1; fi
    b=`sed '2q;d' $versionfile`
    echo $b
    checkout=$(findCheckout $repo)
    cd $checkout || exit 2
    echo $PWD
    git fetch || exit 2
    git tag -a $tagname $b -m "Create tag for $version"  || exit 4
    git push --tags || exit 5
done

. $here/config

if [ "$release_l10n_separately" = 1 ]; then

    . $here/version
    svn mkdir svn+ssh://svn@svn.kde.org/home/kde/tags/KDE/$version -m "Create tag for $version" || exit 7
    cat $here/modules.svn | while read repo branch; do
        echo $repo
        . $here/version
        tagname=v$version
        versionfile=$here/versions/$repo
        if [ ! -f $versionfile ]; then echo "$versionfile not found"; exit 6; fi
        b=`sed '2q;d' $versionfile`
        echo $b
        branch=`echo $branch | sed 's#svn://anonsvn.kde.org#svn+ssh://svn@svn.kde.org#g'`
        svn cp $branch/$repo@$b svn+ssh://svn@svn.kde.org/home/kde/tags/KDE/$version/ -m "Create tag for $version" || exit 8
    done

    l10n_repo=`echo $l10n_repo | sed 's#svn://anonsvn.kde.org#svn+ssh://svn@svn.kde.org#g'`
    svn mkdir svn+ssh://svn@svn.kde.org/home/kde/tags/KDE/$version/kde-l10n -m "Create tag for $version" || exit 9
    for lang in `cat language_list`; do
        echo $lang
        . $here/version
        versionfile=$here/versions/kde-l10n-$lang
        if [ ! -f $versionfile ]; then echo "$versionfile not found"; exit 10; fi
        b=`sed '2q;d' $versionfile`
        echo $b
        echo $l10n_repo
        svn cp $l10n_repo/$lang@$b svn+ssh://svn@svn.kde.org/home/kde/tags/KDE/$version/kde-l10n -m "Create tag for $version" || exit 11
        variants=`svn cat svn+ssh://svn@svn.kde.org/home/kde/tags/KDE/$version/kde-l10n/$lang/pack-with-variants 2> /dev/null` || continue
        for variant in $variants; do
            echo $variant
            svn cp $l10n_repo/$variant@$b svn+ssh://svn@svn.kde.org/home/kde/tags/KDE/$version/kde-l10n -m "Create tag for $version" || exit 12
        done
    done
fi
