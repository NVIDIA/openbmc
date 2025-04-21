SUMMARY = "CPU diagnostic status between BMC and HOST"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://cpu-diag-status.sh \
           "

CPU_DIAG_STATUS_SCRIPT = "cpu-diag-status.sh"

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        cpu-diag-status.service \
        cpu-diag-status.timer \
        "

do_install(){
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/${CPU_DIAG_STATUS_SCRIPT} ${D}/${bindir}/cpu-diag-status.sh
}

