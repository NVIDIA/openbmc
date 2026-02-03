FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://emmc-partition-format-dev.sh"

do_install:append() {
    if ${@bb.utils.contains('BUILD_VAR', 'dbg', 'true', 'false', d)}; then
        rm ${D}/${bindir}/emmc-partition-format.sh
        install -m 0755 ${UNPACKDIR}/emmc-partition-format-dev.sh ${D}/${bindir}/emmc-partition-format.sh
    fi
}
