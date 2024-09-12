FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://spdmd_conf.json"

do_install:append() {
    mkdir -p ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/spdmd_conf.json ${D}${sysconfdir}/spdmd_conf.json
}
