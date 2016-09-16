#!/bin/bash

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { echo "$@" 1>&2; "$@" || die "cannot $*"; }

run_chmod() { try chown -R ${SIGNING_USER}:${SIGNING_GROUP} /repo; }
trap run_chmod EXIT

try cd /repo/

# create the yum repo
try createrepo --database --unique-md-filenames --workers=$(nproc) --retain-old-md=5 .

# sign and verify it
try gpg --default-key ${GPG_SIGNING_KEY_ID} --armor --detach-sign --sign --output repodata/repomd.xml.asc repodata/repomd.xml
sync
sleep 2
try gpg --verify --default-key ${GPG_SIGNING_KEY_ID} repodata/repomd.xml.asc repodata/repomd.xml

# then create a browsable page
try repoview --title "GoCD Yum Repository" .
