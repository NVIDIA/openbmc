SUMMARY = "NVIDIA HMC FRU Write Protect Server"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://hmc-fru-wp.sh \
           file://hmc-fru-write-protect-on.service \
           file://hmc-fru-write-protect-off.service \
           file://pcie-chip-write-protect-off.service \
           file://pcie-chip-write-protect-on.service \
           file://global-wp-on.target \
           file://global-wp-off.target \
           "

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        hmc-fru-write-protect-on.service \
        hmc-fru-write-protect-off.service \
        pcie-chip-write-protect-off.service \
        pcie-chip-write-protect-on.service \
        global-wp-on.target \
        global-wp-off.target \
	"

FILES:${PN} = "${systemd_system_unitdir}/* ${bindir}/*"
do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/hmc-fru-wp.sh ${D}${bindir}/
}
