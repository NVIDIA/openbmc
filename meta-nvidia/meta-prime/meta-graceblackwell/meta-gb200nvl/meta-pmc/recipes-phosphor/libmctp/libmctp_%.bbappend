FILESEXTRAPATHS:append := "${THISDIR}/files:"

inherit obmc-phosphor-dbus-service obmc-phosphor-systemd

RDEPENDS:${PN} = " bash "

DEPENDS += " libusb1 "

EXTRA_OEMESON += " -Denable-usb=enabled "

SRC_URI:append= " file://mctp \
                  file://mctp_cfg_usb.json \
                  file://mctp-usb.rules \
                  file://systemd/mctp-usb-demux@.socket \
                  file://systemd/mctp-usb-demux@.service \
                  file://systemd/mctp-usb-ctrl@.service \
                  file://mctp-ctrl-pmc-usb.conf \
                  file://mctp-demux-pmc-usb.conf \
                 "

SYSTEMD_SERVICE:${PN}:append = " mctp-usb-demux@.service \
                                 mctp-usb-demux@.socket \
                                 mctp-usb-ctrl@.service \
                                "

SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-ctrl.service \
                                 mctp-spi-demux.service \
                                 mctp-spi-demux.socket \
                                 mctp-pcie-ctrl.service \
                                 mctp-pcie-demux.service \
                                 mctp-pcie-demux.socket \
                               "

SYSTEMD_OVERRIDE:${PN}:append = "mctp-ctrl-pmc-usb.conf:mctp-usb-ctrl@.service.d/mctp-ctrl-pmc-usb.conf "
SYSTEMD_OVERRIDE:${PN}:append = "mctp-demux-pmc-usb.conf:mctp-usb-demux@.service.d/mctp-demux-pmc-usb.conf "

FILES:${PN} += "\
                   ${nonarch_base_libdir}/udev/rules.d/mctp-usb.rules \
"

do_install:append() {
    install -d ${D}/${bindir}
    install -d ${D}${datadir}/mctp
    install -m 0644 ${WORKDIR}/mctp ${D}${datadir}/mctp/mctp
    install -m 0644 ${WORKDIR}/mctp_cfg_usb.json ${D}${datadir}/mctp/mctp_cfg_usb.json

    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/mctp-usb.rules ${D}${sysconfdir}/udev/rules.d

    install -m 0644 ${WORKDIR}/systemd/mctp-usb-ctrl@.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-usb-demux@.socket ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-usb-demux@.service ${D}${nonarch_base_libdir}/systemd/system/

    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket
    rm -f ${D}${systemd_system_unitdir}/mctp-usb-demux.service
    rm -f ${D}${systemd_system_unitdir}/mctp-usb-ctrl.service
    rm -f ${D}${systemd_system_unitdir}/mctp-usb-demux.socket
}