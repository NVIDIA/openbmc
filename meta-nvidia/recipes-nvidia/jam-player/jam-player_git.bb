SUMMARY = "Altera JTAG Update JAM uility "
DESCRIPTION = "Utility for updating FPGA code over JTAG"
HOMEPAGE = "None"

# Need correct license info here before upstream.
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit meson pkgconfig

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "git://github.com/NVIDIA/jam-player;protocol=https;branch=develop"
SRCREV = "4c5c7ba5a250f43e590bd245f2ac4d992c43da57"
S = "${WORKDIR}/git"

SRC_URI:append = "\
                  file://jamplayer-update.sh \
"

do_install:append() {
	install -m 0755 ${WORKDIR}/jamplayer-update.sh ${D}${bindir}/
}
