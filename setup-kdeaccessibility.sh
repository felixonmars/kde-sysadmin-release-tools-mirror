#!/bin/bash
# vim: sw=4 et

set -x
set -e

setup_branch_checkout()
{
    git branch --track 4.7 remotes/origin/4.7
    git checkout 4.7
}

svn export -N $BASE/tags/KDE/4.7.0/kdeaccessibility
(
    cd kdeaccessibility

    for d in jovie kaccessible kmag kmousetool kmouth; do

        git clone git@git.kde.org:$d
        ( cd $d; setup_branch_checkout )
    done

)
