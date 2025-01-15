LINUX_VERSION = "6.5.11"
SRCREV="478860e3ed9e29dc7aefdc3534628e37b7e424bd"
KSRC = "git://github.com/NVIDIA/linux;protocol=https;branch=develop-6.5"
# From 4.10+ the COPYING file changed
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://aspeed-bmc-nvidia-gb200nvl-pmc.dts \
                   file://nvidia-gb200nvl-pmc-core.dtsi"

do_configure:append() {
	cp ${WORKDIR}/aspeed-bmc-nvidia-gb200nvl-pmc.dts ${S}/arch/arm/boot/dts/
	cp ${WORKDIR}/nvidia-gb200nvl-pmc-core.dtsi ${S}/arch/arm/boot/dts/
}
