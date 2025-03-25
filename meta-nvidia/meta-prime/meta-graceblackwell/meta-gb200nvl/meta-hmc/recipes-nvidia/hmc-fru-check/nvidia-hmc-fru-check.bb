SUMMARY = "NVIDIA HMC FRU Checker"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""


FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://hmc_fru_checker.sh \
           "

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash busybox"


do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/hmc_fru_checker.sh ${D}${bindir}/
}
