FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " file://mctp "


SYSTEMD_SERVICE:${PN}:remove = " \
                                 mctp-pcie-ctrl.service  \
                                 mctp-pcie-demux.service \
                                 mctp-pcie-demux.socket  \
                               "

do_install:append() {
    install -m 0644 ${WORKDIR}/mctp ${D}${datadir}/mctp/mctp

    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket
}
