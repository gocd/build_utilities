# Requires
# - mount points
#   - `/repo`   (read-write) - Signed repo files (`.deb`)
#   - `/root/.gnupg` (read-write) - the gpg directory
# - environment variables
#   - GPG_SIGNING_KEY_ID
#   - SIGNING_USER
#   - SIGNING_GROUP

FROM ubuntu:xenial
MAINTAINER GoCD Team <go-cd@googlegroups.com>

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install gnupg gnupg-agent debsigs dpkg-sig apt-utils bzip2 gzip unzip zip

COPY createrepo.sh /createrepo.sh
ENV GPG_SIGNING_KEY_ID SOME_SIGNING_KEY

# The actual signing commands

ENTRYPOINT /createrepo.sh
