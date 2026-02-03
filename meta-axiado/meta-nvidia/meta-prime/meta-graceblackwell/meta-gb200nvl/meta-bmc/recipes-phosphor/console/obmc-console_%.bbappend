FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://server.ttyPS1.conf \
            file://81-obmc-console-uart.rules \
            "
do_install:append() {
    rm -f ${D}${sysconfdir}/${BPN}/server.ttyS2.conf
    rm -f ${D}${sysconfdir}/${BPN}/server.ttyUSB1.conf
    rm -f ${D}${sysconfdir}/${BPN}/server.ttyUSB4.conf
    rm -f ${D}${sysconfdir}/${BPN}/server.ttyUSB5.conf
    install -m 0644 ${UNPACKDIR}/server.ttyPS1.conf ${D}${sysconfdir}/${BPN}/
    install -d ${D}/${nonarch_base_libdir}/udev/rules.d
    install -m 0644 ${UNPACKDIR}/81-obmc-console-uart.rules ${D}/${nonarch_base_libdir}/udev/rules.d
}

