SYSTEMD_SERVICE:${PN}:remove = " mctp-restart-notify.service \
                        		"

SYSTEMD_SERVICE:${PN}:remove:gb200nvl-bmc-ut3 = " mctp-spi-ctrl.service "
SYSTEMD_SERVICE:${PN}:remove:gb200nvl-bmc-ut3 = " mctp-spi-demux.service "
SYSTEMD_SERVICE:${PN}:remove:gb200nvl-bmc-ut3 = " mctp-spi-demux.socket "

do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-restart-notify.service
}


do_configure:prepend() {
    sed -i '/ExecStart=\/usr\/bin\/mctp-spi-ctrl $MCTP_SPI_CTRL_OPTS/{n;s/.*/ExecStop=\/usr\/bin\/mctp-vdm-util -c restart_notification -t 0/}' ${S}/systemd/system/mctp-spi-ctrl.service
}

do_install:append:gb200nvl-bmc-ut3() {
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket

    if [ -z "$(ls -A ${D}${nonarch_base_libdir}/systemd/system)" ]; then
        rm -rf ${D}${nonarch_base_libdir}/systemd/system
    fi
}
