#!/bin/bash
# vim: sw=4 et

set -x
set -e

setup_branch_checkout()
{
    git branch --track 4.6 remotes/origin/4.6
    git checkout 4.6
}

svn export -N $BASE/tags/KDE/4.6.2/kdeaccessibility
(
    cd kdeaccessibility

    for d in jovie kaccessible kmag kmousetool kmouth; do

        git clone git@git.kde.org:$d
        ( cd $d; setup_branch_checkout )
    done

)
