SUMMARY = "NVIDIA TegraRCM Tool"
DESCRIPTION = "TegraRCM tool for BMC/HMC"
LICENSE = "CLOSED"
DEPENDS = ""
LIC_FILES_CHKSUM = ""

SRC_URI = "git://github.com/NVIDIA/tegrarcm_v2;protocol=https;branch=develop"
SRCREV = "191a80b9621521e84588859d1fea6542cefbf138"

inherit autotools pkgconfig meson
S = "${WORKDIR}/git"

FILES:${PN} = "${bindir}/tegrarcm_v2"

do_install() {
   install -d ${D}/${bindir}
   install -m 0755 ${B}/tegrarcm_v2 ${D}/${bindir}/
}
