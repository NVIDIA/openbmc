FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/obmc-console;protocol=https;branch=develop"
SRCREV = "a24887729a01298a379527db880db7cd5c13cb90"


SRC_URI:remove = "file://${BPN}.conf"
SRC_URI += "file://server.ttyS2.conf"
SRC_URI += "file://dropbear.env"
OBMC_CONSOLE_TTYS = "ttyS2"
# Install ttyS0 server configuration
do_install:append() {
    # Remove default VUART0 config
    rm -f ${D}${sysconfdir}/${BPN}/server.ttyVUART0.conf
    rm -f ${D}${sysconfdir}/${BPN}.conf
    install -m 0644 ${WORKDIR}/server.ttyS2.conf ${D}${sysconfdir}/${BPN}/
}

