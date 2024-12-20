# Override some values in linux-aspeed.inc and linux-aspeed_git.bb
# with specifics of our Git repo, branch names, and Linux version
#
LINUX_VERSION = "6.6.58"
SRCREV="5f454b4266450a785d6a3a0a21f845c221f8c927"
KSRC = "git://git@gitlab-master.nvidia.com:12051/dgx/bmc/linux.git;protocol=ssh;branch=develop-6.6"
# From 5.10+ the COPYING file changed
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://gb200nvl-bmc.cfg \
                   file://aspeed-bmc-nvidia-gb200nvl-bmc.dts \
                   file://aspeed-bmc-nvidia-gb200nvl-bmc-ut3.dts \
                   file://nvidia-gb200nvl-bmc-core.dtsi \
                   file://0001-remove-H24-and-E26-from-RMII3-group.patch \
                   file://nxp-rtc-PCFPCF85053A.patch \
                   file://0001-Update-shunt-resistor-micro-ohms-for-LTC4286-driver.patch"

do_configure:append() {
	cp ${WORKDIR}/aspeed-bmc-nvidia-gb200nvl-bmc.dts ${S}/arch/arm/boot/dts/
	cp ${WORKDIR}/aspeed-bmc-nvidia-gb200nvl-bmc-ut3.dts ${S}/arch/arm/boot/dts
	cp ${WORKDIR}/nvidia-gb200nvl-bmc-core.dtsi ${S}/arch/arm/boot/dts/
}
