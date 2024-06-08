FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://0001-meta-gb200-nvl-Patch-for-Hotplug-detect-DP-signal.patch \
                    file://ast2600-gb200nvl-bmc-nvidia.dts;subdir=git/arch/${ARCH}/dts/ \
                    "
