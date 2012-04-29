#!/bin/bash
# vim: sw=4 et

set -x
set -e

setup_branch_checkout()
{
    git checkout KDE/4.8
}

svn export -N $BASE/tags/KDE/4.8.2/kdemultimedia
(
    cd kdemultimedia

    for d in mplayerthumbs strigi-multimedia audiocd-kio libkcddb kscd kmix ffmpegthumbs juk dragon libkcompactdisc; do

        rm -rf $d
        git clone git@git.kde.org:$d
        ( cd $d; setup_branch_checkout )
    done

    mv strigi-multimedia strigi-analyzer
    mv audiocd-kio kioslave
    mv dragon dragonplayer
)
