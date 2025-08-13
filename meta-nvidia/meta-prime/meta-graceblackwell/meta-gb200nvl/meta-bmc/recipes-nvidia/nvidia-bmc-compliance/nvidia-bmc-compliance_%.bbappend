FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://hw_checkout.sh \
    file://jtag_test \
    "

INSANE_SKIP:${PN} += "already-stripped"

do_install:append() {
    install -D ${UNPACKDIR}/jtag_test ${D}/${bindir}/
}