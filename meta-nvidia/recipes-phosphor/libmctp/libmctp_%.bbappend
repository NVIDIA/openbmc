FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/libmctp;protocol=https;branch=develop \
           file://default"
SRCREV = "134c629b0c8a02ab716c2ca53ef87eda8422b4e1"

inherit obmc-phosphor-dbus-service obmc-phosphor-systemd

DEPENDS += "json-c \
            i2c-tools \
           "

SYSTEMD_SERVICE:${PN} = "mctp-pcie-demux.service \
                         mctp-pcie-demux.socket \
                         mctp-pcie-ctrl.service \
                         mctp-spi-demux.socket \
                         mctp-spi-demux.service \
                         mctp-spi-ctrl.service \
                         mctp-restart-notify.service \
                        "

CONFFILES:${PN} = "${datadir}/mctp/mctp"

FILES:${PN}:append = "${datadir} ${datadir}/mctp"

do_install:append() {
    install -d ${D}${datadir}/mctp
    if [ -e "${WORKDIR}/mctp-restart-notify.service" ]; then
        install -m 0644 ${WORKDIR}/mctp-restart-notify.service ${D}${nonarch_base_libdir}/systemd/system/mctp-restart-notify.service
    fi
}
