FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN} = " bash "

DEPENDS += " libusb1 "

EXTRA_OEMESON += " -Denable-usb=enabled "
EXTRA_OEMESON += " -Dmctp-in-kernel-enable=enabled "

EXTRA_OEMESON += " -Dmctp-batch-tx=enabled "
EXTRA_OEMESON += " -Dmctp-in-kernel-enable=enabled "

# Needed for systemd dependency: We need to start mctp after the FPGA is up (and on pcie bus)
RDEPENDS:${PN}:append = " nvidia-fpga-ready-monitor "

SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-ctrl.service \
                                 mctp-spi-demux.service \
                                 mctp-spi-demux.socket \
                                 mctp-pcie-ctrl.service  \
                                 mctp-pcie-demux.service \
                                 mctp-pcie-demux.socket  \
                                 mctp-usb-demux.service \
                                 mctp-usb-demux.socket \
                                 mctp-usb-ctrl.service \
                                 mctp-spi0-ctrl.service \
                                 mctp-spi0-demux.service \
                                 mctp-spi0-demux.socket \
                                 mctp-spi2-demux.service \
                               "

SYSTEMD_SERVICE:${PN}:append = "fpga0-ap-recovery.target \
                                "

SRC_URI:append = " file://mctp-usb.rules \
                   file://mctp \
                   file://mctp_cfg_spi0.json \
                   file://mctp_cfg_spi2.json \
                   file://mctp_cfg_usb.json \
                   file://mctp-ctrl-hmc-usb.conf \
                   file://set-fpga0-spi-mux.sh \
                   file://systemd/mctp-spi0-ctrl.service \
                   file://systemd/mctp-spi2-ctrl.service \
                   file://systemd/mctp-usb-ctrl@.service \
                   file://systemd/fpga0-ap-recovery.target \
                   "

SYSTEMD_OVERRIDE:${PN}:append = "mctp-ctrl-hmc-usb.conf:mctp-usb-ctrl@.service.d/mctp-ctrl-hmc-usb.conf "

FILES:${PN} += "\
                   ${nonarch_base_libdir}/udev/rules.d/mctp-usb.rules \
"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${UNPACKDIR}/set-fpga0-spi-mux.sh ${D}/${bindir}/

    install -m 0644 ${UNPACKDIR}/mctp ${D}${datadir}/mctp/mctp
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-usb-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-usb-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-usb-ctrl.service

    install -m 0644 ${UNPACKDIR}/systemd/fpga0-ap-recovery.target ${D}${nonarch_base_libdir}/systemd/system/
}

