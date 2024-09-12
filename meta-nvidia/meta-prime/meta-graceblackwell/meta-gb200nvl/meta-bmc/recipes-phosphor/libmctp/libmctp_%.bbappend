FILESEXTRAPATHS:append := "${THISDIR}/files:"

inherit obmc-phosphor-dbus-service obmc-phosphor-systemd

RDEPENDS:${PN} = " bash "

SRC_URI:append= " file://set-hmc-mux.sh \
                  file://mctp_cfg_smbus1.json \
                  file://mctp_cfg_smbus2.json \
                  file://mctp_cfg_smbus5.json \
                  file://mctp_cfg_smbus14.json \
                  file://mctp_cfg_smbus15.json \
                  file://mctp_cfg_spi0.json \
                  file://mctp_cfg_spi2.json \
                  file://systemd/mctp-i2c1-ctrl.service \
                  file://systemd/mctp-i2c1-demux.service \
                  file://systemd/mctp-i2c1-demux.socket \
                  file://systemd/mctp-i2c2-ctrl.service \
                  file://systemd/mctp-i2c2-demux.service \
                  file://systemd/mctp-i2c2-demux.socket \
                  file://systemd/mctp-i2c5-ctrl.service \
                  file://systemd/mctp-i2c5-demux.service \
                  file://systemd/mctp-i2c5-demux.socket \
                  file://systemd/mctp-i2c14-ctrl.service \
                  file://systemd/mctp-i2c14-demux.service \
                  file://systemd/mctp-i2c14-demux.socket \
                  file://systemd/mctp-i2c15-ctrl.service \
                  file://systemd/mctp-i2c15-demux.service \
                  file://systemd/mctp-i2c15-demux.socket \
                  file://systemd/mctp-spi0-ctrl.service \
                  file://systemd/mctp-spi0-demux.service \
                  file://systemd/mctp-spi0-demux.socket \
                  file://systemd/mctp-spi2-ctrl.service \
                  file://systemd/mctp-spi2-demux.service \
                  file://systemd/fpga0-erot-recovery.target \
                  file://systemd/fpga1-erot-recovery.target \
                  file://systemd/hmc-recovery.target \
                 "

SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-ctrl.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-demux.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-demux.socket"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-ctrl.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-demux.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-demux.socket"

SYSTEMD_SERVICE:${PN}:append = " mctp-i2c1-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c1-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c1-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c2-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c2-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c2-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c5-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c5-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c5-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c14-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c14-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c14-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c15-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c15-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c15-demux.socket"

SYSTEMD_SERVICE:${PN}:append = " mctp-spi0-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-spi0-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-spi0-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-spi2-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-spi2-demux.service"

SYSTEMD_SERVICE:${PN}:append = " fpga0-erot-recovery.target"
SYSTEMD_SERVICE:${PN}:append = " fpga1-erot-recovery.target"
SYSTEMD_SERVICE:${PN}:append = " hmc-recovery.target"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/set-hmc-mux.sh ${D}/${bindir}/

    install -m 0644 ${WORKDIR}/mctp_cfg_smbus1.json ${D}${datadir}/mctp/mctp_cfg_smbus1.json
    install -m 0644 ${WORKDIR}/mctp_cfg_smbus2.json ${D}${datadir}/mctp/mctp_cfg_smbus2.json
    install -m 0644 ${WORKDIR}/mctp_cfg_smbus5.json ${D}${datadir}/mctp/mctp_cfg_smbus5.json
    install -m 0644 ${WORKDIR}/mctp_cfg_smbus14.json ${D}${datadir}/mctp/mctp_cfg_smbus14.json
    install -m 0644 ${WORKDIR}/mctp_cfg_smbus15.json ${D}${datadir}/mctp/mctp_cfg_smbus15.json
    install -m 0644 ${WORKDIR}/mctp_cfg_spi0.json ${D}${datadir}/mctp/mctp_cfg_spi0.json
    install -m 0644 ${WORKDIR}/mctp_cfg_spi2.json ${D}${datadir}/mctp/mctp_cfg_spi2.json

    install -m 0644 ${WORKDIR}/systemd/mctp-i2c1-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c1-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c1-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c2-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c2-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c2-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c5-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c5-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c5-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c14-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c14-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c14-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c15-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c15-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c15-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-spi0-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-spi0-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-spi0-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-spi2-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-spi2-demux.service ${D}${nonarch_base_libdir}/systemd/system/

    install -m 0644 ${WORKDIR}/systemd/fpga0-erot-recovery.target ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/fpga1-erot-recovery.target ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/hmc-recovery.target ${D}${nonarch_base_libdir}/systemd/system/

    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket
}

SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mctp-spi-ctrl.service ', '', d)}"
SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mctp-spi-demux.service ', '', d)}"
SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mctp-spi-demux.socket ', '', d)}"

do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', 'true', 'false', d)}; then
		bbwarn "!!!USING EROTLESS UPDATE FOR THE BMC!!!"
        rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
        rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
        rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    fi
}
