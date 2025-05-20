# Override some values in linux-aspeed.inc and linux-aspeed_git.bb
# with specifics of our Git repo, branch names, and Linux version
#
LINUX_VERSION = "6.12.9"
SRCREV="3eab39c8ce8ef5bb2bb4d42d1d276a41e057c327"
KSRC = "git://github.com/NVIDIA/linux;protocol=https;branch=develop-6.12"
# From 5.10+ the COPYING file changed
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'mctp-inkernel', \
                    'file://in-kernel-mctp/gb200nvl-hmc.cfg file://in-kernel-mctp/aspeed-bmc-nvidia-gb200nvl-hmc.dts ', \
                    'file://gb200nvl-hmc.cfg file://aspeed-bmc-nvidia-gb200nvl-hmc.dts ', d)} \
                   file://nvidia-gb200nvl-hmc-core.dtsi"

do_configure:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'mctp-inkernel', 'true', 'false', d)}; then
        cp ${WORKDIR}/in-kernel-mctp/aspeed-bmc-nvidia-gb200nvl-hmc.dts ${S}/arch/arm/boot/dts/aspeed/
    else
        cp ${WORKDIR}/aspeed-bmc-nvidia-gb200nvl-hmc.dts ${S}/arch/arm/boot/dts/aspeed/
    fi
    cp ${WORKDIR}/nvidia-gb200nvl-hmc-core.dtsi ${S}/arch/arm/boot/dts/aspeed/
}
