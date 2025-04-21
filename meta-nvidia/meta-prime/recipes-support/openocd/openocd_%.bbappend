FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

LIC_FILES_CHKSUM = "file://COPYING;md5=599d2d1ee7fc84c0467b3d19801db870"

SRC_URI = " \
	git://github.com/openocd-org/openocd.git;protocol=https;name=openocd;branch=master \
	git://github.com/msteveb/jimtcl.git;protocol=https;destsuffix=git/jimtcl;name=jimtcl;branch=master \
        file://0001-jtag-JTAG-Driver-remote-debug-support.patch \
        file://0002-jtag-revise-JTAG-Driver-for-kernel-6.1.15.patch \
        file://0003-fix-adding-gdb_port-for-a-failed-examination-target.patch \
        file://grace.cfg \
        file://jtag_driver.cfg \
        file://grace-c1.cfg \
        file://grace-c2.cfg \
        file://grace-cg4.cfg \
"

SRCREV_openocd = "91bd4313444c5a949ce49d88ab487608df7d6c37"
SRCREV_jimtcl = "fcbb4499a6b46ef69e7a95da53e30796e20817f0"

inherit systemd
inherit obmc-phosphor-systemd

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        openocdon.service \
        openocdoff.target \
        "

PV = "0.12+gitr${SRCPV}"
S = "${WORKDIR}/git"

DEPENDS = "libgpiod systemd"
RDEPENDS:${PN} = ""

EXTRA_OECONF = "--disable-doxygen-html --disable-werror --enable-libgpiod --enable-jtag_driver"

do_install:append() {
    rm -f ${D}${datadir}/openocd/scripts/interface/jtag_driver.cfg
    install -m 0644 ${WORKDIR}/jtag_driver.cfg  ${D}${datadir}/openocd/scripts/interface/
    install -m 0644 ${WORKDIR}/grace.cfg  ${D}${datadir}/openocd/scripts/target/
    install -m 0644 ${WORKDIR}/grace-c2.cfg  ${D}${datadir}/openocd/scripts/board/grace-system.cfg
}
