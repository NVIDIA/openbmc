#
# Override some values in "u-boot-common-aspeed_2016.07.inc" with
# specifics of our Git repo, branch names, and source revision.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRCREV="84be4eed920653f2d9904329c6a8261ce608701b"
SRC_URI = "git://github.com/NVIDIA/u-boot;protocol=https;branch=v2019.04-aspeed-openbmc"
SRC_URI:append = " file://u-boot.cfg"

S = "${WORKDIR}/git"

do_configure:append() {
    sed -i 's/ast2600-evb.dtb/${UBOOT_DEVICETREE}.dtb/' ${S}/arch/arm/dts/Makefile
}
