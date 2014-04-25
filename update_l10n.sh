#!/bin/bash

# Make a local checkout of l10n-something/*/messages/<module> into a local dir called l10n
# (to make it branch-independent)

. config

if test -d l10n; then

    # Update existing checkout

    for dir in l10n/*/messages/$l10n_module; do
        ( cd $dir ; svn update )
    done

else

    # Make new checkout

    languages=`svn cat $l10n_repo/subdirs`
    for lang in $languages; do
        mkdir -p l10n/$lang/messages
        svn co $l10n_repo/$lang/messages/$l10n_module l10n/$lang/messages/$l10n_module
    done

fi

