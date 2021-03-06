FROM centos/httpd:latest
MAINTAINER ManageIQ https://github.com/ManageIQ/manageiq-appliance-build

## Atomic/OpenShift Labels
LABEL name="auth-httpd" \
      vendor="ManageIQ" \
      url="http://manageiq.org/" \
      summary="httpd image with external authentication" \
      description="An httpd image which includes packages and configuration necessary for handling external authentication." \
      io.k8s.display-name="Httpd with Authentication" \
      io.k8s.description="An httpd image which includes packages and configuration necessary for handling external authentication." \
      io.openshift.expose-services="80:http" \
      io.openshift.tags="httpd"

## To cleanly shutdown systemd, use SIGRTMIN+3
STOPSIGNAL SIGRTMIN+3

## Install EPEL repo, yum necessary packages for the build without docs, clean all caches
RUN yum -y install centos-release-scl-rh && \
    # SSSD Packages \
    yum -y install --setopt=tsflags=nodocs sssd                         \
                                           sssd-dbus                    \
                                           && \
    # Apache External Authentication Module Packages \
    yum -y install --setopt=tsflags=nodocs mod_auth_kerb                \
                                           mod_authnz_pam               \
                                           mod_intercept_form_submit    \
                                           mod_lookup_identity          \
                                           mod_auth_mellon              \
                                           && \
    # IPA External Authentication Packages \
    yum -y install --setopt=tsflags=nodocs c-ares                       \
                                           certmonger                   \
                                           ipa-client                   \
                                           ipa-admintools               \
                                           && \
    # Active Directory External Authentication Packages \
    yum -y install --setopt=tsflags=nodocs adcli                        \
                                           realmd                       \
                                           real-md                      \
                                           oddjob                       \
                                           oddjob-mkhomedir             \
                                           samba-common                 \
                                           samba-common-tools           \
                                           && \
    yum clean all

## Systemd cleanup base image
RUN (cd /lib/systemd/system/sysinit.target.wants && for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -vf $i; done) & \
     rm -vf /lib/systemd/system/multi-user.target.wants/* && \
     rm -vf /etc/systemd/system/*.wants/* && \
     rm -vf /lib/systemd/system/local-fs.target.wants/* && \
     rm -vf /lib/systemd/system/sockets.target.wants/*udev* && \
     rm -vf /lib/systemd/system/sockets.target.wants/*initctl* && \
     rm -vf /lib/systemd/system/basic.target.wants/* && \
     rm -vf /lib/systemd/system/anaconda.target.wants/*

## Remove any existing configurations
RUN rm -f /etc/httpd/conf.d/*

COPY docker-assets/entrypoint /usr/bin

EXPOSE 80

WORKDIR /etc/httpd

RUN systemctl enable dbus httpd

VOLUME [ "/sys/fs/cgroup" ]

ENTRYPOINT [ "entrypoint" ]
CMD [ "/usr/sbin/init" ]
