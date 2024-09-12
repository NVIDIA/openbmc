FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRCREV="17e25faa2dae09ef0652be7588828d2a41c84ad6"
SRC_URI = "git://github.com/NVIDIA/u-boot;protocol=https;branch=v2019.04-aspeed-openbmc"

SRC_URI:append = " file://fw_env.config"
ENV_CONFIG_FILE = "fw_env.config"
