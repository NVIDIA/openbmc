# Override some values in linux-aspeed.inc and linux-aspeed_git.bb
# with specifics of our Git repo, branch names, and Linux version
#
LINUX_VERSION = "6.12.41"
SRCREV="8d3a4cbe3f39ea40c58820bb270337e1f258ff45"
KSRC = "git://github.com/NVIDIA/linux;protocol=https;branch=develop-6.12"
# From 5.10+ the COPYING file changed
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://gb200nvl-hmc.cfg \
                   file://aspeed-bmc-nvidia-gb200nvl-hmc.dts \
                   file://nvidia-gb200nvl-hmc-core.dtsi"

do_configure:append() {
	cp ${UNPACKDIR}/aspeed-bmc-nvidia-gb200nvl-hmc.dts ${S}/arch/arm/boot/dts/aspeed/
	cp ${UNPACKDIR}/nvidia-gb200nvl-hmc-core.dtsi ${S}/arch/arm/boot/dts/aspeed/
}

require linux-aspeed/cve_linux_kernel_6_12_41_exceptions.inc
