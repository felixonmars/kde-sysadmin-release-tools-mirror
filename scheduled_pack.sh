#!/bin/bash

DELAY=$1

echo "Starting run in ${DELAY}..."

mkdir -p logs
rm -rf logs/*

sleep ${DELAY} && \
	./update_all | tee logs/update.log && \
	./pack_all | tee logs/pack.log && \
	./filterlanguages && \
	pushd sources && \
	sha1sum *.xz > ../sha1sums.txt && \
	popd && \
	pushd sources/kde-l10n && \
	sha1sum *.xz >> ../../sha1sums.txt && \
	ncftpput -p "" kde . *.xz && \
	popd && \
	pushd sources && \
	ncftpput -p "" kde . *.xz

