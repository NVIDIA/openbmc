FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://obmc-shutdown.sh"

do_install:append() {
        install -m 0755 ${UNPACKDIR}/obmc-shutdown.sh ${D}/shutdown
}
