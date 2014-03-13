#!/bin/bash

unset CDPATH

here=$PWD

# We look for the checkouts in $srcdir
# TODO: update this path
srcdir=/d/kde/src

cat $here/modules.git | while read repo branch; do
    cd $srcdir || exit 1
    echo $repo
    . $here/version
    tagname=v$version
    versionfile=$here/versions/$repo
    if [ ! -f $versionfile ]; then echo "$versionfile not found"; exit 1; fi
    b=`sed '2q;d' $versionfile`
    echo $b
    if [ -d $repo ]; then
        cd $repo
    else
        echo "NOT FOUND: $repo"
        exit 3
    fi
    echo $PWD
    git fetch || exit 2
    git tag -a $tagname $b -m "Create tag for $version"  || exit 4
    git push --tags || exit 5
done


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

svn mkdir svn+ssh://svn@svn.kde.org/home/kde/tags/KDE/$version/kde-l10n -m "Create tag for $version" || exit 9
for lang in `cat language_list`; do
    echo $lang
    . l10n_branch
    . $here/version
    versionfile=$here/versions/kde-l10n-$lang
    if [ ! -f $versionfile ]; then echo "$versionfile not found"; exit 10; fi
    b=`sed '2q;d' $versionfile`
    echo $b
    branch=`echo $branch | sed 's#svn://anonsvn.kde.org#svn+ssh://svn@svn.kde.org#g'`
    echo $branch
    svn cp $branch/$lang@$b svn+ssh://svn@svn.kde.org/home/kde/tags/KDE/$version/kde-l10n -m "Create tag for $version" || exit 11
done
