#!/bin/bash

. utils.sh
. config

. version

dest=stable/frameworks/$version

ssh ftpadmin@depot.kde.org "mkdir -p $dest"
ssh ftpadmin@depot.kde.org "chmod o-rx $dest"
rsync --progress -v -a -e "ssh -x" -r sources/* ftpadmin@depot.kde.org:$dest/

# Make diff of local changes to commit (from my own computer, so they don't come from scripty)
git diff > to_commit.diff

echo "Done, now run ./grab_from_scripty.sh locally"

