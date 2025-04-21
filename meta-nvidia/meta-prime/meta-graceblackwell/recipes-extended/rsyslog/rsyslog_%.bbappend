FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG += " rsyslogd rsyslogrt inet regexp uuid  systemd gnutls"

SRC_URI += " \
    file://server.conf \
"