CFG_NAME = "gpio-config.json"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
FILES:${PN}:append = " ${datadir}/${CFG_NAME}"
SRC_URI:append = " file://${CFG_NAME}"

do_install:append() {
    install -d ${D}${datadir}
    install -m 0644 ${WORKDIR}/${CFG_NAME} ${D}${datadir}/
}
