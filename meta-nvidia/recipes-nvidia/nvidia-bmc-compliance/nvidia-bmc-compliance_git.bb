SUMMARY = "NVIDIA HMC HW Checker"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI += " \
    file://hmc_checker.sh \
    "

RDEPENDS:${PN} = "bash"

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/hmc_checker.sh ${D}/${bindir}/
}
