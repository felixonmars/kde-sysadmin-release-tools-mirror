#!/bin/bash

# Creates zip files from all the .tar.xz files found in sources/.
# To be run for frameworks releases.

cd sources
rm -f *.zip
for f in *.tar.xz; do
  tar xf $f
  basename=`echo $f | sed -e 's/\.tar\.xz//'`
  test -d $basename || exit 1
  zip -r $basename.zip $basename || exit 2
  rm -rf $basename
done
