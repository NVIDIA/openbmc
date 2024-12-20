FILESEXTRAPATHS:append := "${THISDIR}/files:"

inherit obmc-phosphor-dbus-service obmc-phosphor-systemd

RDEPENDS:${PN} = " bash "

DEPENDS += " libusb1 "

EXTRA_OEMESON += " -Denable-usb=enabled "

SRC_URI:append= " file://systemd/mctp-usb-demux.socket \
                  file://mctp \
                 "

SYSTEMD_SERVICE:${PN}:append = " mctp-usb-demux.service \
                                 mctp-usb-demux.socket \
                                 mctp-usb-ctrl.service \
                                "

SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-ctrl.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-demux.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-demux.socket"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-ctrl.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-demux.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-demux.socket"


do_install:append() {
    install -d ${D}/${bindir}

    install -m 0644 ${WORKDIR}/systemd/mctp-usb-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/

    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket
    install -d ${D}${datadir}/mctp
    install -m 0644 ${WORKDIR}/mctp ${D}${datadir}/mctp/mctp
}

