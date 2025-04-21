SUMMARY = "NVIDIA HMC I2C Dump Server"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://i2c-dump-server.sh \
           file://i2c-dump-server.service \
           "

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        i2c-dump-server.service \
        "

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/i2c-dump-server.sh ${D}/${bindir}/
}

