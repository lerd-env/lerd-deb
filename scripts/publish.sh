#!/usr/bin/env bash
# Build signed source packages and upload them to the PPA. Launchpad builds and
# publishes the .debs; users get them via apt.
#
#   GPG_KEY_ID=<key> publish.sh <version> [revision]
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

version="${1:?usage: publish.sh <version> [revision]}"
rev="${2:-1}"

: "${GPG_KEY_ID:?GPG_KEY_ID must be set to sign uploads}"

# already_published <package version>
# Launchpad's upload endpoint returns a 550 under load, so a run can die with
# some series already in the archive. Asking the archive what it holds lets a
# re-run finish the remaining series instead of pushing everything again.
already_published() {
    local pkg_version="$1" owner name url count
    owner="${PPA#ppa:}"
    name="${owner#*/}"
    owner="${owner%%/*}"
    url="https://api.launchpad.net/1.0/~${owner}/+archive/ubuntu/${name}"
    count=$(curl -fsSL --get "$url" \
        --data-urlencode "ws.op=getPublishedSources" \
        --data-urlencode "source_name=lerd" \
        --data-urlencode "exact_match=true" \
        --data-urlencode "version=${pkg_version}" \
        | jq '.entries | length')
    [ "${count:-0}" -gt 0 ]
}

# upload <changes file>
# dput gives up on the first 550, which is usually transient.
upload() {
    local changes="$1" attempt
    for attempt in 1 2 3; do
        if dput "$PPA" "$changes"; then
            return 0
        fi
        echo "Attempt ${attempt} failed for $(basename "$changes")."
        sleep $((attempt * 30))
    done
    return 1
}

"$REPO_ROOT/scripts/build-source.sh" "$version" "$rev"

failed=()
for s in "${SERIES[@]}"; do
    if already_published "${version}~${s}${rev}"; then
        echo "${s}: ${version}~${s}${rev} is already in ${PPA}, skipping."
        continue
    fi
    upload "$REPO_ROOT/dist/lerd_${version}~${s}${rev}_source.changes" || failed+=("$s")
done

if [ "${#failed[@]}" -gt 0 ]; then
    echo "::error::Upload failed for: ${failed[*]}. The next run retries just those."
    exit 1
fi

echo "Uploaded lerd ${version} to ${PPA} for: ${SERIES[*]}"
