SUMMARY = "NVIDIA E4830 Post-boot Configuration"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://bmc-boot-complete.service \
           file://common_platform_var.conf \
           "

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash nvidia-mc-lib"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        bmc-boot-complete.service \
        "

do_install() {
    install -d ${D}/etc/default/
    install -m 0755 ${WORKDIR}/common_platform_var.conf ${D}/etc/default/platform_var.conf
}

