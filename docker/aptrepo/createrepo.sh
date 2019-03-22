#!/bin/bash

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { echo "$@" 1>&2; "$@" || die "cannot $*"; }

run_chmod() { try chown -R ${SIGNING_USER}:${SIGNING_GROUP} /repo; }
trap run_chmod EXIT

try cd /repo

# create the package manifest
try apt-ftparchive packages binaries > Packages
try gzip -9 --keep -- Packages
try bzip2 -9 --keep -- Packages

# Generate the `Release` and `InRelease` files and corresponding gpg keys
try apt-ftparchive release . > Release
try gpg --default-key ${GPG_SIGNING_KEY_ID} --digest-algo sha512 --clearsign --output InRelease Release
try gpg --default-key ${GPG_SIGNING_KEY_ID} --digest-algo sha512 --armor --detach-sign --sign --output Release.gpg Release
sync
sleep 2
try gpg --verify --default-key ${GPG_SIGNING_KEY_ID} Release.gpg Release
