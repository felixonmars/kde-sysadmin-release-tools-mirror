rm REVISIONS_AND_HASHES

for d in clean/*; do
    pushd ${d}
    if [[ -d .git ]]; then
        echo ${d#clean/} `cat .git/refs/heads/KDE/4.9` >> ../../REVISIONS_AND_HASHES
    elif [[ -d .svn ]]; then
        echo ${d#clean/} `svn info | sed -n -e '/^Revision: \([0-9]*\).*$/s//\1/p'` >> ../../REVISIONS_AND_HASHES
    fi
    popd
done
