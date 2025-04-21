FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://hw_checkout.sh \
    "

do_install:append() {
    install -D ${WORKDIR}/hw_checkout.sh ${D}/${bindir}/
}