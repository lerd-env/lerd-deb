#!/usr/bin/env bash
# Build a signed source package per Ubuntu series into dist/. These are what get
# uploaded to the PPA; Launchpad's build farm compiles them into .debs.
#
#   build-source.sh <version> [revision]
#
# Set GPG_KEY_ID to sign; without it the packages are built unsigned (dry run).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

version="${1:?usage: build-source.sh <version> [revision]}"
rev="${2:-1}"

work="$(mktemp -d)"
bins="$work/bins"
download_binaries "$version" "$bins"
mkdir -p "$REPO_ROOT/dist"

sign_args=(-us -uc)
[ -n "${GPG_KEY_ID:-}" ] && sign_args=("-k${GPG_KEY_ID}")

for s in "${SERIES[@]}"; do
    tree="$work/lerd-$s"
    prepare_tree "$version" "$s" "$rev" "$bins" "$tree"
    (cd "$tree" && dpkg-buildpackage -S -sa -d "${sign_args[@]}")
    # Copy every artifact the upload needs: the .changes plus the .dsc and
    # .tar.xz it references (the latter two have no _source infix).
    cp "$work"/lerd_${version}~${s}${rev}* "$REPO_ROOT/dist/"
done

echo "Source packages in dist/:"
ls -1 "$REPO_ROOT/dist/"*_source.changes
