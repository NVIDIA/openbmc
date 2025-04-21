SUMMARY = "NVIDIA HMC SatMC enumerator"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

FILES:${PN} = " ${bindir}/cpu-boot-handler.sh"
                

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        cpu-boot-done.service \
        cpu-boot-undone.service \
        "

S = "${WORKDIR}"

SRC_URI = " \
      file://cpu-boot-handler.sh \
      file://cpu-boot-done.service \
      file://cpu-boot-undone.service \
     "

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/cpu-boot-handler.sh ${D}/${bindir}/cpu-boot-handler.sh

    install -d ${D}${systemd_system_unitdir}
}

