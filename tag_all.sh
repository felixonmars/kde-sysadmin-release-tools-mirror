#!/bin/bash

unset CDPATH

here=$PWD

# We look for the checkouts in subdirs (frameworks/, kdesupport/) of $srcdir
# TODO: adapt this for KDE SC releases
srcdir=/d/kde/src/5

cat $here/modules.git | while read repo branch; do
    cd $srcdir || exit 1
    echo $repo
    . $here/version
    tagname=v$version
    versionfile=$here/versions/$repo
    if [ ! -f $versionfile ]; then echo "$versionfile not found"; exit 1; fi
    b=`sed '2q;d' $versionfile`
    echo $b
    if [ -d frameworks/$repo ]; then
        cd frameworks/$repo
    elif [ -d kdesupport/$repo ]; then
        cd kdesupport/$repo || exit 2
    else
        echo "NOT FOUND: $repo"
        exit 3
    fi
    echo $PWD
    git tag -a $tagname $b -m "Create tag for $version"  || exit 4
    git push --tags || exit 5
done

