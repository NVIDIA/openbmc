SUMMARY = "IO board detection"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://io-board-detect.sh \
           file://io-board-detect.service \
           "

DEPENDS = "systemd"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " io-board-detect.service"

do_install() {
    install -d ${D}/${bindir}
    install -D ${WORKDIR}/io-board-detect.sh ${D}${bindir}/io-board-detect.sh
    install -D ${WORKDIR}/io-board-detect.service ${D}${base_libdir}/systemd/system/io-board-detect.service
}
