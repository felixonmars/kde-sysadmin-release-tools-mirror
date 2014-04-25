#!/bin/bash

. config

if [ "$release_l10n_separately" = "0" ]; then
    bash update_l10n.sh
fi

cat modules.git | while read repo branch; do
(
    bash pack.sh $repo $1
)
done

cat modules.svn | while read repo branch; do
(
    bash pack.sh $repo $1
)
done

if [ "$release_l10n_separately" = "1" ]; then
    bash pack_l10n.sh
fi

# for sending to kde-packager@kde.org
cat versions/* > REVISIONS_AND_HASHES
