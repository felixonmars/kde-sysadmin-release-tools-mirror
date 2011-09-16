#!/bin/bash
# vim: sw=4 et

set -x
set -e

setup_branch_checkout()
{
    git checkout KDE/4.7
}

svn export -N $BASE/tags/KDE/4.7.0/kdeedu
(
    cd kdeedu

    for d in blinken cantor kalgebra kalzium kanagram kbruch kgeography khangman kig kiten klettres kmplot kstars ktouch kturtle kwordquiz libkdeedu marble parley rocs step; do

        git clone git@git.kde.org:$d
        ( cd $d; setup_branch_checkout )
    done
)
