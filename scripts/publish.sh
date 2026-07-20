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

"$REPO_ROOT/scripts/build-source.sh" "$version" "$rev"

for s in "${SERIES[@]}"; do
    dput "$PPA" "$REPO_ROOT/dist/lerd_${version}~${s}${rev}_source.changes"
done

echo "Uploaded lerd ${version} to ${PPA} for: ${SERIES[*]}"
