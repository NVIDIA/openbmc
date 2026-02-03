#FIXEME: KWS-7327
SRC_URI:remove = "file://systemd/mctp-spi0-ctrl.service \
                  file://systemd/mctp-spi0-demux.service \
                  file://systemd/mctp-spi0-demux.socket \
                  "

SYSTEMD_SERVICE:${PN}:remove = " mctp-spi0-ctrl.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-spi0-demux.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-spi0-demux.socket"

do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi0-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi0-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi0-demux.socket
}
