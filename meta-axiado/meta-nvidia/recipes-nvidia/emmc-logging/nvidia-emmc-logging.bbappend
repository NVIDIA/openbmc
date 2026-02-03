FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://check_logmount-dev.sh \
            file://emmc-logging-dev.sh \
            "

do_install:append() {
    if ${@bb.utils.contains('BUILD_VAR', 'dbg', 'true', 'false', d)}; then
        rm ${D}${bindir}/check_logmount.sh
        rm ${D}${bindir}/emmc-logging.sh
        install -m 0755 ${UNPACKDIR}/check_logmount-dev.sh ${D}${bindir}/check_logmount.sh
        install -m 0755 ${UNPACKDIR}/emmc-logging-dev.sh ${D}${bindir}/emmc-logging.sh
    fi
}
