FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://spdmd_conf.json"

EXTRA_OEMESON:append = " -Denable-in-kernel-mctp=enabled "
do_install:append() {
    mkdir -p ${D}${sysconfdir}
    install -m 0644 ${UNPACKDIR}/spdmd_conf.json ${D}${sysconfdir}/spdmd_conf.json
}
