#
# Override some values in "u-boot-common-aspeed_2016.07.inc" with
# specifics of our Git repo, branch names, and source revision.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRCREV="84be4eed920653f2d9904329c6a8261ce608701b"
SRC_URI = "git://github.com/NVIDIA/u-boot;protocol=https;branch=v2019.04-aspeed-openbmc \
           file://0001-Set-drive-strengths-to-600Mv.patch \
           "
SRC_URI:append = " file://u-boot.cfg"
SRC_URI += "file://oem_dss_4096_0.pem;sha256sum=98112defd6bbfaf0ced07349b86efb2ba09c766a19e53bc34ea3e990ace16bc7"
SRC_URI += "file://oem_dss_4096_1.pem;sha256sum=73bb01360721de3fec2ae9532e98397ee9ec319c150c4d6d976d983261eeaa21"

S = "${WORKDIR}/git"

SOCSEC_SIGN_ENABLE = "0"
SOCSEC_SIGN_KEY = "${WORKDIR}/oem_dss_4096_1.pem"

do_configure:append() {
    sed -i 's/ast2600-evb.dtb/${UBOOT_DEVICETREE}.dtb/' ${S}/arch/arm/dts/Makefile
}
