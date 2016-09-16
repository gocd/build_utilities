#!/bin/bash

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { echo "$@" 1>&2; "$@" || die "cannot $*"; }

run_chmod() { try chown -R ${SIGNING_USER}:${SIGNING_GROUP} /signed; }
trap run_chmod EXIT

try cp -rfv /unsigned/* /signed
try dpkg-sig --verbose --sign builder -k ${GPG_SIGNING_KEY_ID} /signed/*.deb
try gpg --armor --output /tmp/GPG-KEY-GOCD --export ${GPG_SIGNING_KEY_ID}
try apt-key add /tmp/GPG-KEY-GOCD
try dpkg-sig --verbose --verify /signed/*.deb
