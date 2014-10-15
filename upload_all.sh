#!/bin/bash

. utils.sh
. config

. version

# version=x.y.z ==> dir=x.y
# Patch-level releases go into the same directory, since they are typically just one framework
dir=`echo $version | sed -e 's/\.[0-9]$//'`

dest=stable/frameworks/$dir

ssh ftpadmin@depot.kde.org "mkdir -p $dest"
ssh ftpadmin@depot.kde.org "chmod o-rx $dest"
rsync --progress -v -a -e "ssh -x" -r sources/* ftpadmin@depot.kde.org:$dest/

# Make diff of local changes to commit (from my own computer, so they don't come from scripty)
git diff > to_commit.diff

echo "Done, now run ./grab_from_scripty.sh locally"

