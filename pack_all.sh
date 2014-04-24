#!/bin/bash

# Only useful for frameworks
bash update_l10n.sh

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

# Only useful for workspace and apps
# bash pack_l10n.sh

# for sending to kde-packager@kde.org
cat versions/* > REVISIONS_AND_HASHES
