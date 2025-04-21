FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://init-options"
SRC_URI:append = " file://init-options-overlay"
FILES:${PN}:append = " ${@bb.utils.contains('BUILD_TYPE', 'prod', '/init-options-overlay', '', d)}"
FILES:${PN}:append = " ${@bb.utils.contains('BUILD_TYPE', 'debug', '/init-options-overlay', '', d)}"

do_install:append() {
    install -m 0644 ${WORKDIR}/init-options ${D}/init-options
    ISPROD="${@bb.utils.contains("BUILD_TYPE", "prod", "1", "0", d)}"
    ISDEBUG="${@bb.utils.contains("BUILD_TYPE", "debug", "1", "0", d)}"
    if [ "${ISPROD}" = "1" ] ||  [ "${ISDEBUG}" = "1" ]; then
        install -m 0644 ${WORKDIR}/init-options-overlay ${D}/init-options-overlay
    fi
}
