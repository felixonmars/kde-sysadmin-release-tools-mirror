#!/bin/bash

unset CDPATH

here=$PWD

. config
. utils.sh

cmd=
if [ "$dry_run" = "1" ]; then
    cmd=echo
fi

# Read ECM version
repo=extra-cmake-modules
. $here/version
ecm_version=$version

if [ ! -d $srcdir ]; then
    echo "$srcdir does not exist, please fix srcdir variable"
    exit 1
fi

step=$1
if [ "$step" != step1 -a "$step" != step2 ]; then
    echo "Argument missing: step1 (update sources and update version number) or step2 (update version requirements)"
    exit 2
fi

cat $here/modules.git | while read repo branch; do
    echo $repo
    . $here/version
    checkout=$(findCheckout $repo)
    cd $checkout || exit 2
    echo $PWD
    $cmd git checkout master || exit 3
    if [ "$step" = step1 ]; then
        if [ "$repo" = extra-cmake-modules ]; then
            ecm_major=`echo $ecm_version | cut -d. -f1`
            ecm_minor=`echo $ecm_version | cut -d. -f2`
            ecm_patch=`echo $ecm_version | cut -d. -f3`
            $cmd perl -pi -e '$_ =~ s/\Q$1/'$ecm_major'/ if (/^set.ECM_MAJOR_VERSION ([0-9]*)/);' CMakeLists.txt
            $cmd perl -pi -e '$_ =~ s/\Q$1/'$ecm_minor'/ if (/^set.ECM_MINOR_VERSION ([0-9]*)/);' CMakeLists.txt
            $cmd perl -pi -e '$_ =~ s/\Q$1/'$ecm_patch'/ if (/^set.ECM_PATCH_VERSION ([0-9]*)/);' CMakeLists.txt
            $cmd git commit -a -m "Upgrade ECM version to $ecm_version."
        else
            $cmd perl -pi -e '$_ =~ s/\Q$1/'$version'/ if (/^set.KF5_VERSION \"([^\"]*)\"/);' CMakeLists.txt
            test -f setup.py && $cmd perl -pi -e '$_ =~ s/\Q$1/'$version'/ if (/^ +version=.(.*).,/);' setup.py # for kapidox
            $cmd git commit -a -m "Upgrade KF5 version to $version."
        fi
    else
        $cmd perl -pi -e 's/ECM [0-9]+\.[0-9]+\.[0-9]+/ECM '$ecm_version'/g' CMakeLists.txt
        $cmd perl -pi -e '$_ =~ s/\Q$1/'$version'/ if (/^set.KF5_DEP_VERSION \"([^\"]*)\"/);' CMakeLists.txt
        $cmd git commit -a -m "Upgrade ECM and KF5 version requirements for $version release."
    fi
    $cmd git pull --rebase
    $cmd git push
done