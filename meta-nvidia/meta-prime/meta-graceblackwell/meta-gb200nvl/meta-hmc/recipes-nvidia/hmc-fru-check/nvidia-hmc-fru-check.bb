SUMMARY = "NVIDIA HMC FRU Checker"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://hmc_fru_checker.sh \
           file://nvidia-hmc-fru-check.service \
           "

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash busybox"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        ${PN}.service \
	"

FILES:${PN} = "${systemd_system_unitdir}/* ${bindir}/*"
do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/hmc_fru_checker.sh ${D}${bindir}/
}
