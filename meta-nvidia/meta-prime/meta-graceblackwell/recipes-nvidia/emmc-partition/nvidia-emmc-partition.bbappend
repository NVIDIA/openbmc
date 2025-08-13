FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
                   file://emmc-utils \
                 "

do_install:append() {
    install -m 0755 ${UNPACKDIR}/emmc-utils/create-partition.sh ${D}/${bindir}/
    install -m 0644 ${UNPACKDIR}/emmc-utils/emmc-mount.conf ${D}/usr/share/emmc/
}
