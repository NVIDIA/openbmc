LINUX_VERSION = "6.5.11"
SRCREV= "d6610f16c5cf14dad9e97ffa9be992a8aad4ddd2"
KSRC = "git://github.com/NVIDIA/linux;protocol=https;nobranch=1"
# From 4.10+ the COPYING file changed
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://gb200nvl-hmc.cfg \
                   file://aspeed-bmc-nvidia-gb200nvl-hmc.dts \
                   file://nvidia-gb200nvl-hmc-core.dtsi"

do_configure:append() {
	cp ${WORKDIR}/aspeed-bmc-nvidia-gb200nvl-hmc.dts ${S}/arch/arm/boot/dts/
	cp ${WORKDIR}/nvidia-gb200nvl-hmc-core.dtsi ${S}/arch/arm/boot/dts/
}
