#!/bin/bash
# vim: sw=4 et

git_branch_name=master

setup_branch_checkout()
{
    git checkout master
}

set -x

cd clean
for module in $(<../modules.git); do
    if ! test -d $module/.git ; then
        if test -d $module; then
            echo "ERROR: $module exists but is no git repo!"
            exit 1
        fi
    fi

    if ! test -d $module; then
        git clone git@git.kde.org:$module
    fi

    if test -d $module; then
        cd $module
        setup_branch_checkout
        cd ..
    fi
done
cd ..
