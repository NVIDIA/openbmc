FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://write-protect.sh \
           "

WRITE_PROTECT_SCRIPT = "write-protect.sh"

do_install(){
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/${WRITE_PROTECT_SCRIPT} ${D}/${bindir}/write-protect.sh
}
