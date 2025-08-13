# Override some values in linux-aspeed.inc and linux-aspeed_git.bb
# with specifics of our Git repo, branch names, and Linux version
#
LINUX_VERSION = "6.6.83"
SRCREV="8ebc80a25f9d9bf7a8e368b266d5b740c485c362"
KSRC = "git://github.com/NVIDIA/linux;protocol=https;branch=dev-6.6"
# From 5.10+ the COPYING file changed
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
file://gb200nvl-bmc.cfg \
file://0001-ARM-dts-aspeed-Add-device-tree-for-Nvidia-s-GB200NVL.patch \
file://0002-usb-Add-base-USB-MCTP-definitions.patch \
file://0003-net-mctp-Add-MCTP-USB-transport-driver.patch \
file://0004-drivers-net-mctp-usb-Port-for-kernel-6.6.patch"


#do_configure:append() {
#	cp ${UNPACKDIR}/aspeed-bmc-nvidia-gb200nvl-bmc.dts ${S}/arch/arm/boot/dts/
#	cp ${UNPACKDIR}/aspeed-bmc-nvidia-gb200nvl-bmc-ut3.dts ${S}/arch/arm/boot/dts
#	cp ${UNPACKDIR}/nvidia-gb200nvl-bmc-core.dtsi ${S}/arch/arm/boot/dts/
#}
