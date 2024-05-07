FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://ast2600-gb200nvl-bmc-nvidia.dts;subdir=git/arch/${ARCH}/dts/"
