#!/usr/bin/env bash
# Build a binary .deb for the host architecture and assert it installs the lerd
# binary. This is the smoke test that runs in CI and can be run on an Ubuntu VM.
#
#   build-binary.sh <version> [revision]
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

version="${1:?usage: build-binary.sh <version> [revision]}"
rev="${2:-1}"
series="${TEST_SERIES:-noble}"

work="$(mktemp -d)"
bins="$work/bins"
download_binaries "$version" "$bins"

tree="$work/lerd-$series"
prepare_tree "$version" "$series" "$rev" "$bins" "$tree"
(cd "$tree" && dpkg-buildpackage -b -us -uc -d)

deb="$(ls "$work"/lerd_*_*.deb | head -1)"
echo "built: $deb"
contents="$(dpkg-deb -c "$deb")"
echo "$contents"
if ! grep -qE ' \./usr/bin/lerd$' <<<"$contents"; then
    echo "FAIL: /usr/bin/lerd not present in the package" >&2
    exit 1
fi
mkdir -p "$REPO_ROOT/dist"
cp "$deb" "$REPO_ROOT/dist/"
echo "OK: $(basename "$deb") installs /usr/bin/lerd"
