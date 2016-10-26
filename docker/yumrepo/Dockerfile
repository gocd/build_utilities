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

RUN yum clean all && \
    yum install --assumeyes epel-release && \
    yum --assumeyes update && \
    yum install --assumeyes createrepo repoview yum-utils rpm-build fakeroot yum-utils gnupg2 zip unzip gzip bzip2 tar rpm && \
    yum clean all

COPY createrepo.sh /createrepo.sh
ENV GPG_SIGNING_KEY_ID SOME_SIGNING_KEY

# The actual signing commands

CMD /createrepo.sh
