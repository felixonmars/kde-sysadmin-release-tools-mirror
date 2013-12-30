#!/bin/bash

unset CDPATH

. version
tagname=v$version
here=$PWD

# We look for the checkouts in subdirs (frameworks/, kdesupport/) of $srcdir
# TODO: adapt this for KDE SC releases
srcdir=/d/kde/src/5

cat $here/modules.git | while read repo branch; do
    cd $srcdir || exit 1
    echo $repo
    b=`sed '2q;d' $here/versions/$repo`
    echo $b
    cd frameworks/$repo || cd kdesupport/$repo || exit 2
    echo $PWD
    git fetch || exit 3
    git tag -a $version $b -m "Create tag for $version"  || exit 4
    git push --tags || exit 5
done

