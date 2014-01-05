#!/bin/bash

unset CDPATH

. version
tagname=v$version
here=$PWD

# We look for the checkouts in $srcdir
# TODO: update this path
srcdir=/d/kde/src

cat $here/modules.git | while read repo branch; do
    cd $srcdir || exit 1
    echo $repo
    b=`sed '2q;d' $here/versions/$repo`
    echo $b
    cd $repo || exit 2
    echo $PWD
    git fetch || exit 3
    git tag -a $tagname $b -m "Create tag for $version"  || exit 4
    git push --tags || exit 5
done

