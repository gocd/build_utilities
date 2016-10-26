# Requires
# - mount points
#   - `/unsigned` (read-only)  - Input files (`.deb`) that should be signed
#   - `/signed`   (read-write) - Signed output files (`.deb`)
#   - `/root/.gnupg` (read-write) - the gpg directory
# - environment variables
#   - GPG_SIGNING_KEY_ID
#   - SIGNING_USER
#   - SIGNING_GROUP

FROM ubuntu:xenial
MAINTAINER GoCD Team <go-cd@googlegroups.com>

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install gnupg gnupg-agent debsigs dpkg-sig apt-utils bzip2 gzip unzip zip && \
    apt-get autoclean -y && \
    apt-get autoremove -y

COPY sign.sh /sign.sh
ENV GPG_SIGNING_KEY_ID SOME_SIGNING_KEY

# The actual signing commands

CMD /sign.sh
