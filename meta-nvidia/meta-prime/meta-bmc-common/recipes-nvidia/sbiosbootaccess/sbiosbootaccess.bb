
SUMMARY = "NVIDIA SBios Boot Access Service"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash nvidia-mc-lib biosconfig-manager"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

FILES:${PN} = " ${bindir}/delete-hi-user.sh \
                ${bindir}/control-bios-host-interface.sh "
                

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "cpu-boot-done.service cpu-boot-undone.service"

S = "${WORKDIR}"

SRC_URI = " \
      file://delete-hi-user.sh \
      file://control-bios-host-interface.sh \
      file://cpu-boot-done.service \
      file://cpu-boot-undone.service \
     "

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/delete-hi-user.sh ${D}/${bindir}/delete-hi-user.sh
    install -m 0755 ${S}/control-bios-host-interface.sh ${D}/${bindir}/control-bios-host-interface.sh

    install -d ${D}${systemd_system_unitdir}
}



