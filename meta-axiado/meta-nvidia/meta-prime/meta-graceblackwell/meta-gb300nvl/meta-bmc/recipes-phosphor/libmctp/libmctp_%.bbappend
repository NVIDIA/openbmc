FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit obmc-phosphor-dbus-service obmc-phosphor-systemd

RDEPENDS:${PN} = " bash "

DEPENDS += " libusb1 "

EXTRA_OEMESON += " -Denable-usb=enabled "
EXTRA_OEMESON += " -Dmctp-in-kernel-enable=enabled "

SRC_URI:append= " file://set-hmc-mux.sh \
                  file://systemd/fpga0-erot-recovery.target \
                  file://systemd/fpga1-erot-recovery.target \
                  file://systemd/hmc-recovery.target \
                  file://mctp \
                 "

SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-ctrl.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-demux.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-demux.socket"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-ctrl.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-demux.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-demux.socket"
SYSTEMD_SERVICE:${PN}:remove = " mctp-usb-ctrl@.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-usb-demux@.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-usb-demux@.socket"

SYSTEMD_SERVICE:${PN}:append = " fpga0-erot-recovery.target"
SYSTEMD_SERVICE:${PN}:append = " fpga1-erot-recovery.target"
SYSTEMD_SERVICE:${PN}:append = " hmc-recovery.target"

SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mctp-spi0-ctrl.service ', '', d)}"
SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mctp-spi0-demux.service ', '', d)}"
SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mctp-spi0-demux.socket ', '', d)}"

FILES:${PN} += "\
                   ${nonarch_base_libdir}/udev/rules.d/mctp-usb.rules \
"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${UNPACKDIR}/set-hmc-mux.sh ${D}/${bindir}/

    install -m 0644 ${UNPACKDIR}/systemd/fpga0-erot-recovery.target ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${UNPACKDIR}/systemd/fpga1-erot-recovery.target ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${UNPACKDIR}/systemd/hmc-recovery.target ${D}${nonarch_base_libdir}/systemd/system/

    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-usb-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-usb-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-usb-ctrl.service
    install -d ${D}${datadir}/mctp
    install -m 0644 ${UNPACKDIR}/mctp ${D}${datadir}/mctp/mctp
}
