# lerd-deb

> Open-source Herd-like local PHP development environment, packaged for
> Debian/Ubuntu and published to the [`ppa:lerd/lerd`](https://launchpad.net/~lerd/+archive/ubuntu/lerd)
> Launchpad PPA.

[![CI](https://github.com/lerd-env/lerd-deb/actions/workflows/ci.yml/badge.svg)](https://github.com/lerd-env/lerd-deb/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/lerd-env/lerd)](https://github.com/lerd-env/lerd/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-lerd.sh-blue)](https://lerd.sh)
[![Reddit](https://img.shields.io/badge/Reddit-r%2Flerd-ff2d20?logo=reddit)](https://reddit.com/r/lerd)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/5JK54s7xCC)

![Lerd dashboard tour](https://raw.githubusercontent.com/lerd-env/lerd/main/docs/assets/screenshots/tour.gif)

[Lerd](https://lerd.sh) runs Nginx, PHP-FPM, and your services as rootless
[Podman](https://podman.io) containers: automatic `.test` domains with HTTPS,
per-project PHP versions, one-click databases and services, a built-in web UI,
TUI, CLI and MCP server. No Docker, no sudo, no system pollution. This repo
makes it a first-class Ubuntu citizen: `apt install lerd` brings up the whole
stack on its own, and every update after that arrives with your normal system
updates.

## Install

The PPA carries packages for every Ubuntu release in standard support and for
the current development release (the `SERIES` list in `scripts/common.sh`).
On one of those:

```bash
sudo add-apt-repository ppa:lerd/lerd
sudo apt update
sudo apt install lerd
```

On a typical single-user desktop that is the whole setup: the package finishes
it automatically, the machine-global steps as root, then the per-user install
as the user who ran sudo. When it cannot (no systemd, not installed through
sudo, a multi-user machine) it prints a note and you run `lerd install` once
yourself.

On any other release, `add-apt-repository` leaves behind a source entry that
fails every later `apt update`, because the PPA has nothing published for that
series. If that has already happened, remove it with
`sudo add-apt-repository --remove ppa:lerd/lerd`. Either way, use the
[script installer](https://lerd.sh) instead:

```bash
curl -fsSL https://lerd.sh/install.sh | bash
```

Updates arrive through apt like any other package:

```bash
sudo apt upgrade
```

## How it works

Launchpad PPAs build from signed **source** packages, not prebuilt binaries. lerd
needs a very recent Go toolchain and a network-fetched Svelte UI, neither of which
the network-isolated Launchpad build farm can provide. So this repo does not build
lerd from source. Instead it repackages the binaries already published on each
[upstream release](https://github.com/lerd-env/lerd/releases): the source tarball
ships the prebuilt `lerd` (and `lerd-tray` on amd64), and `debian/rules` installs
the one matching the architecture Launchpad is building for.

The package uses the `3.0 (native)` source format so the prebuilt binaries can live
in the source tarball without a separate orig tarball. Each upstream version is
uploaded once per Ubuntu series with a `~series` version suffix (for example
`1.29.0~noble1`).

## Automation

`.github/workflows/publish.yml` polls the upstream repo daily. When a new release
appears it builds signed source packages and `dput`s them to the PPA, then records
the version in `published-version`. Manual runs are limited to repo admins.

`.github/workflows/ci.yml` builds a binary `.deb` on every push and asserts it
installs `/usr/bin/lerd`.

## Prerequisites

The publishing workflow needs an OpenPGP key that is registered on the Launchpad
account that owns the PPA:

- `GPG_PRIVATE_KEY` secret: the ASCII-armored private key used to sign uploads.
- The matching public key added at `launchpad.net/~<account>/+editpgpkeys`, and its
  email confirmed on the account.

Enable the `arm64` processor in the PPA settings if you want arm64 builds.

## Manual publish

```bash
sudo apt install devscripts debhelper dput
# dry run, unsigned source build:
scripts/build-source.sh 1.29.0
# build a binary .deb and check it installs the binary:
scripts/build-binary.sh 1.29.0
# real signed upload:
GPG_KEY_ID=<your-key-id> scripts/publish.sh 1.29.0
```
