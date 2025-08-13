FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

EXTRA_OEMESON += "-Ddebug_log=1"

SRC_URI:append = " \
    file://gpu_nsm_maptbl_platform.conf \
    "

do_install:append() {
    install -m 0644 ${UNPACKDIR}/gpu_nsm_maptbl_platform.conf ${D}${datadir}/sw-einj
}


