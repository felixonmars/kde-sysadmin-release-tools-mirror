#!/bin/bash
# vim: sw=4 et

set -x
set -e

setup_branch_checkout()
{
    git checkout KDE/4.8
}

svn export -N $BASE/tags/KDE/4.8.3/kdemultimedia
svn export -N $BASE/tags/KDE/4.8.3/kdemultimedia/kioslave kdemultimedia/kioslave
mkdir kdemultimedia/cmake
svn export -N $BASE/tags/KDE/4.8.3/kdemultimedia/cmake/modules kdemultimedia/cmake/modules
(
    cd kdemultimedia

    for d in mplayerthumbs strigi-multimedia audiocd-kio libkcddb kscd kmix ffmpegthumbs juk dragon libkcompactdisc; do

        rm -rf $d
        git clone git@git.kde.org:$d
        ( cd $d; setup_branch_checkout )
    done

    mv strigi-multimedia strigi-analyzer
    mv audiocd-kio kioslave/audiocd
    mv dragon dragonplayer
)
