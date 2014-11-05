#!/bin/bash

. version
. utils.sh
. config

force=$1

unset CDPATH

mkdir -p sources/kde-l10n
mkdir -p versions

svn cat $l10n_repo/scripts/autogen.sh > /tmp/kde-l10n-autogen.sh
chmod +x /tmp/kde-l10n-autogen.sh

remove_stuff()
{
    rm -rf internal 
    rm -rf docmessages 
    rm -rf webmessages 
    rm -rf messages/*/desktop_* 
    rm -rf messages/others 
    rm -rf messages/index.lokalize
    rm -rf docs/others 
    rm -rf messages/kdenonbeta 
    rm -rf docs/kdenonbeta 
    rm -rf messages/extragear-*
    rm -rf messages/www
    rm -rf messages/playground-*
    rm -rf messages/no-auto-merge
    rm -rf docs/extragear-* 
    rm -rf docs/playground-*
    rm -rf messages/kdekiosk
    rm -rf docs/kdekiosk 
    rm -rf messages/play* 
    rm -rf messages/kdereview 
    rm -rf */koffice 
    rm -rf */calligra
    rm -rf messages/kdevelop
    rm -rf docs/kdevelop
    rm -rf messages/kdevplatform
    rm -rf docs/kdevplatform
    rm -rf docs/kdewebdev/quanta*
    rm -rf messages/kdewebdev/quanta*
    rm -rf no-auto-merge
    rm -rf */no-auto-merge
}

remove_stuff_kf5()
{
    remove_stuff
    rm -rf */kde-workspace
}

pack_variants()
{
    if test -f pack-with-variants; then
        cat pack-with-variants | while read vdir; do
            echo $vdir
            pack_lang $vdir 0
        done
        rm -f pack-with-variants
    fi
}

pack_lang()
{
    lang=$1
    rootLang=$2
    checkout=1
    while [ $checkout -eq 1 ]; do
        umask 000
        MANIFEST="`mktemp -t`"

        rev=`get_svn_rev`
        svn export $l10n_repo/$lang@ $lang@ &> /dev/null
        svn export $l10n_repo2/$lang@ 2$lang@ &> /dev/null
        rev2=`get_svn_rev`
        if [ "$rev" = "$rev2" ]; then
            if [ $rootLang -eq 1 ]; then
                echo "$rev"
                echo "$rev" >> $versionFilePath
            fi
            cd $lang
            remove_stuff
            cd ../2$lang
            remove_stuff_kf5
            cd ..
            cp -R 2$lang/* $lang/
            cd $lang
            pack_variants
            rev3=`get_svn_rev`
            # Check again after pack_variants just in case
            # something happened in between
            if [ "$rev" = "$rev3" ]; then
                cd ..
                if [ $rootLang -eq 1 ]; then
                    # Delete empty folders, we do it a few times
                    # in case there is empty dirs inside empty dirs
                    find $lang -type d -empty -delete
                    find $lang -type d -empty -delete
                    find $lang -type d -empty -delete
                    find $lang -type d -empty -delete
                    /tmp/kde-l10n-autogen.sh $lang
                    mv $lang kde-l10n-$lang-$version
                    find kde-l10n-$lang-$version -type f |sed 's/^\.*\/*//'|sort > MANIFEST
                    tar cf kde-l10n-$lang-$version.tar --owner 0 --group 0 --numeric-owner --no-recursion --files-from MANIFEST
                    xz -9 kde-l10n-$lang-$version.tar
                    mv kde-l10n-$lang-$version.tar.xz sources/kde-l10n
                    rm -f MANIFEST
                fi
                checkout=0
            fi
        fi
        if [ $rootLang -eq 1 ]; then
            rm -rf $lang 2$lang kde-l10n-$lang-$version
        fi
    done
}

cat language_list | while read lang; do
    finalDestination=sources/kde-l10n/kde-l10n-$lang-$version.tar.xz
    versionFilePath=versions/kde-l10n-$lang
    repoLine="$l10n_repo/$lang"
    # Passing a very "up" root since we are shipping kde4 and kf5 translations
    branch=svn://anonsvn.kde.org/home/kde/branches/stable/

    checkDownloadUptodate "svn" $finalDestination
    uptodate=$?
    if [ $uptodate = 1 ]; then
        echo "kde-l10n-$lang is already up to date, no need to re-download. Use -f as parameter if you want to force"
        continue
    fi

    echo "$repoLine"
    echo "$repoLine" > $versionFilePath
    pack_lang $lang 1
    sha256sum $finalDestination >> $versionFilePath
done

rm -f /tmp/kde-l10n-autogen.sh
