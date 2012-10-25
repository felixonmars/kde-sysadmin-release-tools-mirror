#!/bin/bash
# vim: sw=4 et

#set -x

if test -z "$BASE"; then
    BASE="git@git.kde.org:"
fi

cd clean
cat ../modules.git | while read module branch; do
    if ! test -d $module/.git ; then
        if test -d $module; then
            echo "ERROR: $module exists but is no git repo!"
            exit 1
        fi
    fi

    if ! test -d $module; then
        git clone $BASE$module
    fi

    if test -d $module; then
        cd $module
        git checkout $branch
        cd ..
    fi
done
cd ..
