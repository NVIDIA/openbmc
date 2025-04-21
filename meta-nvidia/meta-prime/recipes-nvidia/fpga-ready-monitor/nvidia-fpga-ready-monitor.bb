SUMMARY = "NVIDIA BMC FPGA Ready Monitor"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS += "libgpiod"
DEPENDS += "systemd"

S = "${WORKDIR}"

FILESEXTRAPATHS:append := ":${THISDIR}/files"

BIN = "fpga_ready_monitor.sh"
SYSDSVC = "nvidia-fpga-ready-monitor.service"

FPGA_RDY_SVC = "nvidia-set-fpga-on.service"
FPGA_NOT_RDY_SVC = "nvidia-set-fpga-off.service"

FPGA_RDY_TARGET = "nvidia-fpga-notready.target"
FPGA_NOT_RDY_TARGET = "nvidia-fpga-ready.target"

SRC_URI = "file://${BIN} \
           file://${SYSDSVC} \
	   file://${FPGA_RDY_SVC} \
	   file://${FPGA_NOT_RDY_SVC} \
	   file://${FPGA_RDY_TARGET} \
	   file://${FPGA_NOT_RDY_TARGET} \
          "

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "${SYSDSVC}"

do_install() {
    install -d ${D}${bindir}
    install -d ${D}${systemd_system_unitdir}
    install -m 0755 ${WORKDIR}/${BIN} ${D}${bindir}/

    install -m 0644 ${S}/${FPGA_RDY_SVC} ${D}${systemd_system_unitdir}/
    install -m 0644 ${S}/${FPGA_NOT_RDY_SVC} ${D}${systemd_system_unitdir}/

    install -m 0644 ${S}/${FPGA_RDY_TARGET} ${D}${systemd_system_unitdir}/
    install -m 0644 ${S}/${FPGA_NOT_RDY_TARGET} ${D}${systemd_system_unitdir}/
}

FILES:${PN}:append = " ${bindir}/${BIN}"

FILES:${PN}:append = " ${systemd_system_unitdir}/${FPGA_RDY_SVC}"
FILES:${PN}:append = " ${systemd_system_unitdir}/${FPGA_NOT_RDY_SVC}"

FILES:${PN}:append = " ${systemd_system_unitdir}/${FPGA_RDY_TARGET}"
FILES:${PN}:append = " ${systemd_system_unitdir}/${FPGA_NOT_RDY_TARGET}"
