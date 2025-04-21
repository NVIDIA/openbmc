# Override some values in linux-aspeed.inc and linux-aspeed_git.bb
# with specifics of our Git repo, branch names, and Linux version
#
LINUX_VERSION = "6.5.11"
SRCREV="35cc52abcada30627f24f33e3dda1737f8df0764"
KSRC = "git://github.com/NVIDIA/linux;protocol=https;branch=Core-24.09-1_br"
# From 5.10+ the COPYING file changed
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://gb200nvl-hmc.cfg \
                   file://aspeed-bmc-nvidia-gb200nvl-hmc.dts \
                   file://nvidia-gb200nvl-hmc-core.dtsi"

do_configure:append() {
	cp ${WORKDIR}/aspeed-bmc-nvidia-gb200nvl-hmc.dts ${S}/arch/arm/boot/dts/
	cp ${WORKDIR}/nvidia-gb200nvl-hmc-core.dtsi ${S}/arch/arm/boot/dts/
}
