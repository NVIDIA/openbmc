SUMMARY = "NVIDIA emmc logging and Dump storage"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://emmc-logging.sh \
           file://nvidia-emmc-logging.service \
           "

DEPENDS = "systemd"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        nvidia-emmc-logging.service \
        "

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/emmc-logging.sh ${D}/${bindir}/
}

