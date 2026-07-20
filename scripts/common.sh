#!/usr/bin/env bash
# Shared helpers for building lerd source/binary packages from upstream release
# binaries. Sourced by build-source.sh, build-binary.sh and publish.sh.
set -euo pipefail

RELEASE_REPO="lerd-env/lerd"
PPA="${PPA:-ppa:lerd/lerd}"

# Ubuntu series to publish to. LTS releases only by default.
SERIES=(jammy noble)

# Maintainer identity for the changelog trailer and the signing key UID. The
# email must match a GPG key registered on the uploading Launchpad account.
: "${DEBFULLNAME:=George Dumitrescu}"
: "${DEBEMAIL:=george@dumitres.co}"
export DEBFULLNAME DEBEMAIL

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# download_binaries <version> <destdir>
# Lays the release binaries out as <destdir>/{amd64,arm64}/lerd (+ amd64/lerd-tray).
download_binaries() {
    local version="$1" dest="$2"
    local base="https://github.com/${RELEASE_REPO}/releases/download/v${version}"
    local tmp; tmp="$(mktemp -d)"
    mkdir -p "$dest/amd64" "$dest/arm64"
    curl -fsSL -o "$tmp/amd64.tgz" "$base/lerd_${version}_linux_amd64.tar.gz"
    curl -fsSL -o "$tmp/arm64.tgz" "$base/lerd_${version}_linux_arm64.tar.gz"
    tar -xzf "$tmp/amd64.tgz" -C "$dest/amd64" lerd lerd-tray
    tar -xzf "$tmp/arm64.tgz" -C "$dest/arm64" lerd
    chmod 0755 "$dest"/amd64/lerd "$dest"/amd64/lerd-tray "$dest"/arm64/lerd
    rm -rf "$tmp"
}

# render_changelog <version> <series> <revision>
render_changelog() {
    local version="$1" series="$2" rev="$3"
    cat <<EOF
lerd (${version}~${series}${rev}) ${series}; urgency=medium

  * Automated packaging of lerd ${version} for ${series}.

 -- ${DEBFULLNAME} <${DEBEMAIL}>  $(date -R)
EOF
}

# prepare_tree <version> <series> <revision> <binaries_dir> <destdir>
# Builds a self-contained source tree ready for dpkg-buildpackage.
prepare_tree() {
    local version="$1" series="$2" rev="$3" bins="$4" dest="$5"
    rm -rf "$dest"
    mkdir -p "$dest/prebuilt"
    cp -r "$REPO_ROOT/debian" "$dest/debian"
    cp -r "$bins/amd64" "$dest/prebuilt/amd64"
    cp -r "$bins/arm64" "$dest/prebuilt/arm64"
    render_changelog "$version" "$series" "$rev" > "$dest/debian/changelog"
}
