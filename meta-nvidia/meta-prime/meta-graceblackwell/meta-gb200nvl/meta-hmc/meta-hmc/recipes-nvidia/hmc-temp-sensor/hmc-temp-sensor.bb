SUMMARY = "NVIDIA HMC Temperature Sensor"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://hmc-temp-sensor.sh \
           file://hmc-temp-sensor.service \
           "

DEPENDS = "systemd"
RDEPENDS:${PN} = "busybox bash"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        hmc-temp-sensor.service \
        "

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/hmc-temp-sensor.sh ${D}/${bindir}/
}

