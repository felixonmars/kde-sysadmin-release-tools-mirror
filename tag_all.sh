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
    git tag -a $tagname $b -m "Create tag for $version"  || exit 4
    git push --tags || exit 5
done

