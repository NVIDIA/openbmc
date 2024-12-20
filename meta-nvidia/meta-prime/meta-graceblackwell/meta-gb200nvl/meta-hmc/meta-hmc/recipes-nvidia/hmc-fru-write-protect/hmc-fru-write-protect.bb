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
           file://hmc-fru-write-protect@.service \
           "

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        ${PN}@.service \
	"

FILES:${PN} = "${systemd_system_unitdir}/* ${bindir}/*"
do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/hmc-fru-wp.sh ${D}${bindir}/
    install -d ${D}${systemd_system_unitdir}
    ln -s -r ${D}${systemd_system_unitdir}/${PN}@.service ${D}${systemd_system_unitdir}/${PN}@on.service
    ln -s -r ${D}${systemd_system_unitdir}/${PN}@.service ${D}${systemd_system_unitdir}/${PN}@off.service
}
