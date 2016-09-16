#!/bin/bash

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { echo "$@" 1>&2; "$@" || die "cannot $*"; }

run_chmod() { try chown -R ${SIGNING_USER}:${SIGNING_GROUP} /signed; }
trap run_chmod EXIT

try cp -rfv /unsigned/* /signed
try rpm --addsign --define "_gpg_name ${GPG_SIGNING_KEY_ID}" /signed/*.rpm
try gpg --armor --output /tmp/GPG-KEY-GOCD --export ${GPG_SIGNING_KEY_ID}
try rpm --import /tmp/GPG-KEY-GOCD
try rpm --checksig /signed/*.rpm
