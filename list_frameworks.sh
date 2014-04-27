#!/bin/bash

# Make the list of frameworks to release, based on the "release" key of the yaml files
# Output: modules.git

. config

. utils.sh

out=modules.git

cp -f /dev/null $out

for framework in `ls -1 $srcdir/frameworks`; do

    metainfo=$srcdir/frameworks/$framework/metainfo.yaml
    if [ -f $metainfo ]; then
        release=`readYamlEntry $metainfo release`
        if [ "$release" = "true" ]; then
            echo $framework master >> $out
        fi
    fi

done

