#!/bin/bash

. utils.sh
. config

. version

dest=stable/frameworks/$version

ssh ftpadmin@depot.kde.org "mkdir $dest"
ssh ftpadmin@depot.kde.org "chmod o-rx $dest"
rsync --progress -v -a -e "ssh -x" -r sources/* ftpadmin@depot.kde.org:$dest/


