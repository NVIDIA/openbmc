SUMMARY = "NVIDIA BMC Reset Check"
DESCRIPTION = "Log BMC reset event"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = "\
         systemd \
         "

RDEPENDS:${PN} = "bash nvidia-event-logs"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI += " \
            file://bmc_reset_check.sh \
           "

SYSTEMD_SERVICE:${PN} = "bmc-reset-check.service"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/bmc_reset_check.sh ${D}/${bindir}
}
