SUMMARY = "NVIDIA POWER State Init service for HMC"
PR = "r1"
PV = "0.2"

# FIXME: once having the correct license info for upstream
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS += "systemd"

RDEPENDS:${PN} = "bash"

S = "${WORKDIR}"

FILESEXTRAPATHS:append := ":${THISDIR}/files"

SYSDSVC = "hmc-power-state.service"
SRC_URI = "file://${SYSDSVC} \
           file://hmc-power-state \
          "

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "${SYSDSVC}"
SYSTEMD_LINK_${PN} += "${@compose_list(d, 'FMT', 'PWRSTS_SERVICE')}"

do_install () {
        install -d ${D}${bindir}
        install -m 0755 ${S}/hmc-power-state ${D}${bindir}/
}
