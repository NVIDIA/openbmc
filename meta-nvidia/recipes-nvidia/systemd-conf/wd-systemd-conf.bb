SUMMARY = "NVIDIA systemd-conf for HW watchdog enablement"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILEXTRAPATHS:prepend := "${THISDIR}/files:"


SRC_URI += " \
            file://watchdog.conf \
           "

FILES:${PN} += " \
    ${sysconfdir}/systemd/system.conf.d/watchdog.conf  \
"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/system.conf.d
    install -m 0644 ${WORKDIR}/watchdog.conf ${D}${sysconfdir}/systemd/system.conf.d
}
