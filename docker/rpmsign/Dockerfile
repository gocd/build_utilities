# Requires
# - mount points
#   - `/unsigned` (read-only)  - Input files (`.deb`) that should be signed
#   - `/signed`   (read-write) - Signed output files (`.deb`)
#   - `/root/.gnupg` (read-write) - the gpg directory
# - environment variables
#   - GPG_SIGNING_KEY_ID
#   - SIGNING_USER
#   - SIGNING_GROUP

FROM centos:6
MAINTAINER GoCD Team <go-cd@googlegroups.com>

RUN yum clean all
RUN yum install --assumeyes epel-release
RUN yum --assumeyes update
RUN yum install --assumeyes createrepo repoview yum-utils rpm-build fakeroot yum-utils gnupg2 zip unzip gzip bzip2 tar rpm

COPY sign.sh /sign.sh
ENV GPG_SIGNING_KEY_ID SOME_SIGNING_KEY

# The actual signing commands

ENTRYPOINT /sign.sh
