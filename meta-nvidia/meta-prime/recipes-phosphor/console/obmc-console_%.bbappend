FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/obmc-console;protocol=https;branch=develop"
SRCREV = "0e24874221b0b3ab2ec63c22916222f4b2c4ab9f"

CONSOLE_SERVER_CONF_FMT = "file://server.{0}.conf"
CONSOLE_CLIENT_CONF_FMT = "file://client.{0}.conf"
CONSOLE_OBMC_CONSOLE_SOCKET_FMT = "file://systemd/obmc-console-{0}.socket"
CONSOLE_OBMC_CONSOLE_CONF_FMT = "file://systemd/use-socket-{0}.conf"
OBMC_CONSOLE_SOCKET_FMT = "obmc-console-{0}.socket"
CONSOLE_SERVER_SOCKET_FMT = "obmc-console@{0}.socket"
CONSOLE_SERVER_SERVICE_FMT = "obmc-console@{0}.service"

SRC_URI:remove = "file://${BPN}.conf"
SRC_URI += "file://dropbear.env"
OBMC_CONSOLE_TTYS = "ttyS2 ttyUSB1 ttyUSB4 ttyUSB5 "
OBMC_CONSOLE_USBTTYS = "ttyUSB1 ttyUSB4 ttyUSB5"
CONSOLE_CLIENT = "2201 2202 2203"
SRC_URI += " \
             ${@compose_list(d, 'CONSOLE_SERVER_CONF_FMT', 'OBMC_CONSOLE_TTYS')} \
             ${@compose_list(d, 'CONSOLE_CLIENT_CONF_FMT', 'CONSOLE_CLIENT')} \
             ${@compose_list(d, 'CONSOLE_OBMC_CONSOLE_SOCKET_FMT', 'OBMC_CONSOLE_USBTTYS')} \
             ${@compose_list(d, 'CONSOLE_OBMC_CONSOLE_CONF_FMT', 'OBMC_CONSOLE_USBTTYS')} \
           "
SYSTEMD_SERVICE:${PN}:append = " \
                                  ${@compose_list(d, 'OBMC_CONSOLE_SOCKET_FMT', 'OBMC_CONSOLE_USBTTYS')} \
                                  ${@compose_list(d, 'CONSOLE_SERVER_SOCKET_FMT', 'OBMC_CONSOLE_TTYS')} \
                                  ${@compose_list(d, 'CONSOLE_SERVER_SERVICE_FMT', 'OBMC_CONSOLE_TTYS')} \
                                "
# Install ttyS0 server configuration`
do_install:append() {
    # Remove default VUART0 config
    rm -f ${D}${sysconfdir}/${BPN}/server.ttyVUART0.conf
    rm -f ${D}${sysconfdir}/${BPN}.conf

    USBTTYS="ttyUSB1 ttyUSB4 ttyUSB5"
    for USBTTY in $USBTTYS; do
        install -d ${D}${systemd_system_unitdir}/obmc-console-${USBTTY}@.service.d
        install -m 0644 ${WORKDIR}/systemd/obmc-console-${USBTTY}.socket ${D}${systemd_system_unitdir}/
        install -m 0644 ${WORKDIR}/image/usr/lib/systemd/system/obmc-console-ssh@.service ${D}${systemd_system_unitdir}/obmc-console-${USBTTY}@.service
        install -m 0644 ${WORKDIR}/systemd/use-socket-${USBTTY}.conf ${D}${systemd_system_unitdir}/obmc-console-${USBTTY}@.service.d/
    done
    install -m 0644 ${WORKDIR}/server.*.conf ${D}${sysconfdir}/${BPN}/
    install -m 0644 ${WORKDIR}/client.*.conf ${D}${sysconfdir}/${BPN}/
}

