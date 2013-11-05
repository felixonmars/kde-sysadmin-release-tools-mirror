#!/bin/bash

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

bash pack_l10n.sh
