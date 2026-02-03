FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
# Specify the path to fix the error during clean build
SRC_URI += "file://emmc-utils/create-partition.sh \
            file://emmc-utils/emmc-mount.conf \
            "
