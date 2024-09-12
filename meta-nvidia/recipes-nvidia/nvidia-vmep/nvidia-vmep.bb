SUMMARY = "NVIDIA VME player Library"
DESCRIPTION = "Lattice CPLD"
LICENSE = "CLOSED"

LIC_FILES_CHKSUM = ""

inherit meson
S = "${WORKDIR}/git"

SRC_URI = "git://github.com/NVIDIA/ispvme;protocol=https;branch=main"
SRCREV = "414cdf580d3a96eed52029d4e9c0305d48f9e3d3"

PV = "0.1+git${SRCPV}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = "\
                  file://vme-player.sh \
                  file://vme-jtag-busy.target \
"
FILES:${PN}:append = " ${systemd_system_unitdir}/vme-jtag-busy.target "

do_install:append() {
	install -m 0755 ${WORKDIR}/vme-player.sh ${D}${bindir}/
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/vme-jtag-busy.target ${D}${systemd_system_unitdir}
}
