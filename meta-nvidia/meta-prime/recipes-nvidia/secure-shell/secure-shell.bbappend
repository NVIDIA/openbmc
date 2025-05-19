FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://secure-shell.sh"

do_install:append() {
    rm ${D}${bindir}/secure-shell.sh
    install -m 0755 ${WORKDIR}/secure-shell.sh ${D}${bindir}/
}
