#!/bin/bash
# vim: sw=4 et

set -x
set -e

setup_branch_checkout()
{
    git branch --track 4.6 remotes/origin/4.6
    git checkout 4.6
}

svn export -N $BASE/tags/KDE/4.6.2/kdeedu
(
    cd kdeedu

    for d in blinken cantor kalgebra kalzium kanagram kbruch kgeography khangman kig kiten klettres kmplot kstars ktouch kturtle kwordquiz libkdeedu parley rocs step; do

        git clone git@git.kde.org:$d
        ( cd $d; setup_branch_checkout )
    done


    git clone git@git.kde.org:marble
    (cd marble; git checkout kde-4.6 )

)
