#!/bin/zsh

rm -f REVISIONS_AND_HASHES tags.git to_commit.diff
scp scripty@l10n.kde.org:~/frameworks_packaging/release-tools/REVISIONS_AND_HASHES .
scp scripty@l10n.kde.org:~/frameworks_packaging/release-tools/tags.git .
scp scripty@l10n.kde.org:~/frameworks_packaging/release-tools/to_commit.diff .
git apply to_commit.diff
