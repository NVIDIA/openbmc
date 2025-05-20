FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN} = " bash "

DEPENDS += " libusb1 "

EXTRA_OEMESON += " -Denable-usb=enabled "

EXTRA_OEMESON += " -Dmctp-batch-tx=enabled "
EXTRA_OEMESON += "${@bb.utils.contains('DISTRO_FEATURES', 'mctp-inkernel', '-Dmctp-in-kernel-enable=enabled', '', d)}"

# Needed for systemd dependency: We need to start mctp after the FPGA is up (and on pcie bus)
RDEPENDS:${PN}:append = " nvidia-fpga-ready-monitor "

SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-ctrl.service \
                                 mctp-spi-demux.service \
                                 mctp-spi-demux.socket \
                                 mctp-pcie-ctrl.service  \
                                 mctp-pcie-demux.service \
                                 mctp-pcie-demux.socket  \
                               "

SYSTEMD_SERVICE:${PN}:append = " mctp-usb-ctrl@.service \
                                 mctp-spi0-ctrl.service \         
                                 fpga0-ap-recovery.target \
                                 ${@bb.utils.contains('DISTRO_FEATURES', 'mctp-inkernel', '', \
                                 'mctp-usb-demux@.socket \
                                 mctp-usb-demux@.service \
                                 mctp-spi0-demux.service \
                                 mctp-spi0-demux.socket \
                                 mctp-spi2-demux.service \
                                 mctp-spi2-ctrl.service', d)} \
                                "

SRC_URI:append = " file://mctp \   
                   file://mctp_cfg_usb.json \
                   file://mctp-ctrl-hmc-usb.conf \
                   file://set-fpga0-spi-mux.sh \
                   file://systemd/mctp-usb-ctrl@.service \
                   file://systemd/fpga0-ap-recovery.target \
                   ${@bb.utils.contains('DISTRO_FEATURES', 'mctp-inkernel', \
                        'file://in-kernel-mctp/mctp_cfg_spi0.json \
                        file://in-kernel-mctp/mctp-usb.rules \
                        file://in-kernel-mctp/mctp-spi0-ctrl.service', \
                        \
                        'file://mctp-demux-hmc-usb.conf \
                        file://systemd/mctp-spi0-demux.service \
                        file://systemd/mctp-spi0-demux.socket \
                        file://systemd/mctp-spi0-ctrl.service \
                        file://mctp_cfg_spi0.json \
                        file://mctp-usb.rules \
                        file://systemd/mctp-spi2-demux.service \
                        file://systemd/mctp-spi2-ctrl.service \
                        file://mctp_cfg_spi2.json \
                        file://systemd/mctp-usb-demux@.socket \
                        file://systemd/mctp-usb-demux@.service \
                        ', d)} \
                   "

SYSTEMD_OVERRIDE:${PN}:append = "mctp-ctrl-hmc-usb.conf:mctp-usb-ctrl@.service.d/mctp-ctrl-hmc-usb.conf "
SYSTEMD_OVERRIDE:${PN}:append =  " ${@bb.utils.contains('DISTRO_FEATURES', 'mctp-inkernel', \
                                '', 'mctp-demux-hmc-usb.conf:mctp-usb-demux@.service.d/mctp-demux-hmc-usb.conf', d)}"

FILES:${PN} += "\
                   ${nonarch_base_libdir}/udev/rules.d/mctp-usb.rules \
"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/set-fpga0-spi-mux.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/mctp ${D}${datadir}/mctp/mctp

    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    # For dynamic multi-bridge, only keep the template unit file
    rm -f ${D}${systemd_system_unitdir}/mctp-usb-demux.service
    rm -f ${D}${systemd_system_unitdir}/mctp-usb-ctrl.service
    rm -f ${D}${systemd_system_unitdir}/mctp-usb-demux.socket

    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/mctp_cfg_usb.json ${D}${datadir}/mctp/mctp_cfg_usb.json
    install -m 0644 ${WORKDIR}/systemd/mctp-usb-ctrl@.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/fpga0-ap-recovery.target ${D}${nonarch_base_libdir}/systemd/system/
    if ${@bb.utils.contains('DISTRO_FEATURES', 'mctp-inkernel', 'true', 'false', d)}; then
        install -m 0644 ${WORKDIR}/in-kernel-mctp/mctp-usb.rules ${D}${sysconfdir}/udev/rules.d
        install -m 0644 ${WORKDIR}/in-kernel-mctp/mctp_cfg_spi0.json ${D}${datadir}/mctp/mctp_cfg_spi0.json
        install -m 0644 ${WORKDIR}/in-kernel-mctp/mctp-spi0-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/

    else
        install -m 0644 ${WORKDIR}/mctp-usb.rules ${D}${sysconfdir}/udev/rules.d
        install -m 0644 ${WORKDIR}/systemd/mctp-spi0-demux.service ${D}${nonarch_base_libdir}/systemd/system/
        install -m 0644 ${WORKDIR}/systemd/mctp-spi0-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
        install -m 0644 ${WORKDIR}/systemd/mctp-spi0-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
        install -m 0644 ${WORKDIR}/mctp_cfg_spi0.json ${D}${datadir}/mctp/mctp_cfg_spi0.json
        
        install -m 0644 ${WORKDIR}/systemd/mctp-spi2-demux.service ${D}${nonarch_base_libdir}/systemd/system/
        install -m 0644 ${WORKDIR}/systemd/mctp-spi2-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
        install -m 0644 ${WORKDIR}/mctp_cfg_spi2.json ${D}${datadir}/mctp/mctp_cfg_spi2.json
        
        install -m 0644 ${WORKDIR}/systemd/mctp-usb-demux@.socket ${D}${nonarch_base_libdir}/systemd/system/
        install -m 0644 ${WORKDIR}/systemd/mctp-usb-demux@.service ${D}${nonarch_base_libdir}/systemd/system/

    fi
}

