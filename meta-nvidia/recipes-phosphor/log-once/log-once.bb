SUMMARY = "Create RF event log based on uboot env variable"
DESCRIPTION = "Create RF event log based on uboot env variable"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

RDEPENDS:${PN} = "${@d.getVar('PREFERRED_PROVIDER_u-boot-fw-utils', True) or 'u-boot-fw-utils'}"

inherit systemd
inherit obmc-phosphor-systemd

RDEPENDS:${PN} = "bash"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "file://log-once.service \
           file://rf-log.sh"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        log-once.service \
        "

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/rf-log.sh ${D}/${bindir}/
}
