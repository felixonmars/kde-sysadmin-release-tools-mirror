#!/bin/bash
# vim: sw=4 et

set -x
set -e

setup_branch_checkout()
{
    git branch --track 4.7 remotes/origin/4.7
    git checkout 4.7
}

svn export -N $BASE/tags/KDE/4.7.0/kdeutils
(
    cd kdeutils

    for d in ark filelight kcalc kcharselect kdf kfloppy kgpg kremotecontrol ktimer kwallet printer-applet superkaramba sweeper; do

        git clone git@git.kde.org:$d
        ( cd $d; setup_branch_checkout )
    done

)
