#!/bin/zsh

rm -f REVISIONS_AND_HASHES tags.git to_commit.diff
ssh scripty@l10n.kde.org 'cd frameworks_packaging/release-tools ; git diff > to_commit.diff'
scp scripty@l10n.kde.org:~/frameworks_packaging/release-tools/{REVISIONS_AND_HASHES,to_commit.diff,changelog} .
test -s to_commit.diff && git apply to_commit.diff
