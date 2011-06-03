#!/bin/bash
# vim: sw=4 et

set -x
set -e

setup_branch_checkout()
{
    git branch --track KDE/4.6 remotes/origin/KDE/4.6
    git checkout KDE/4.6
}

svn export $BASE/tags/KDE/4.6.1/kdegraphics
(
    cd kdegraphics

    for d in kamera kgamma kcolorchooser gwenview kolourpaint ksaneplugin ksnapshot kruler svgpart ; do
        rm -rf $d
        rm -rf doc/$d
        sed -i -e "s,add_subdirectory.*$d.*,," doc/CMakeLists.txt

        git clone git@git.kde.org:$d
        ( cd $d; setup_branch_checkout )
    done

    (
        cd libs
        for d in libkdcraw libkexiv2 libkipi libksane; do
            rm -rf $d
            git clone git@git.kde.org:$d
            (cd $d; setup_branch_checkout )
        done
    )

    rm -rf strigi-analyzer
    git clone git@git.kde.org:kdegraphics-strigi-analyzer strigi-analyzer
    ( cd strigi-analyzer; setup_branch_checkout )

    rm -rf thumbnailers
    git clone git@git.kde.org:kdegraphics-thumbnailers thumbnailers
    ( cd thumbnailers; setup_branch_checkout )

    rm -rf mobipocket
    git clone git@git.kde.org:mobipocket mobipocket
    ( cd mobipocket; git checkout 4.6 )
    echo "add_subdirectory(mobipocket)" >> CMakeLists.txt
)
