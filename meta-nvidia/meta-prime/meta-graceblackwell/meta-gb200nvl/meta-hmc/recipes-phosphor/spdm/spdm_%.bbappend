FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://spdmd_conf.json"

EXTRA_OEMESON += "${@bb.utils.contains('DISTRO_FEATURES', 'mctp-inkernel', ' -Denable-in-kernel-mctp=enabled', '', d)}"
do_install:append() {
    mkdir -p ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/spdmd_conf.json ${D}${sysconfdir}/spdmd_conf.json
}
