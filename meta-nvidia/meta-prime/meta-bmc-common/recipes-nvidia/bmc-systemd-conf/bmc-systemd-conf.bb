SUMMARY = "NVIDIA Grace BMC systemd-conf for status IP assignment to hostusb0 "
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
            file://systemd-networkd-wait-online-override.conf \
           "

FILES:${PN} += " \
    ${sysconfdir}/systemd/system/systemd-networkd-wait-online.service.d/override.conf \
"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/network
    install -d ${D}${sysconfdir}/systemd/system/systemd-networkd-wait-online.service.d
    install -m 0644 ${WORKDIR}/systemd-networkd-wait-online-override.conf ${D}${sysconfdir}/systemd/system/systemd-networkd-wait-online.service.d/override.conf
}
