#!/bin/bash

# Make a local checkout of l10n-something/*/messages/<module> into a local dir called l10n
# (to make it branch-independent)

. config
unset CDPATH

languages=`svn cat $l10n_repo/subdirs`
for lang in $languages; do
    if test -d l10n/$lang/messages/$l10n_module; then
        ( cd l10n/$lang/messages/$l10n_module ; svn cleanup ; svn update )
        test -d l10n/$lang/docs/$l10n_module && ( cd l10n/$lang/docs/$l10n_module ; svn cleanup ; svn update )
        test -d l10n/$lang/scripts/$l10n_module && ( cd l10n/$lang/scripts/$l10n_module ; svn cleanup ; svn update )
    else
        # Make new checkout
        mkdir -p l10n/$lang/messages
        svn co $l10n_repo/$lang/messages/$l10n_module l10n/$lang/messages/$l10n_module
        mkdir -p l10n/$lang/docs
        svn co $l10n_repo/$lang/docs/$l10n_module l10n/$lang/docs/$l10n_module
        mkdir -p l10n/$lang/scripts
        svn co $l10n_repo/$lang/scripts/$l10n_module l10n/$lang/scripts/$l10n_module
    fi
done
