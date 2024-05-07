SYSTEMD_SERVICE:${PN}:remove = " mctp-restart-notify.service \
                        		"

do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-restart-notify.service
}


do_configure:prepend() {
    sed -i '/ExecStart=\/usr\/bin\/mctp-spi-ctrl $MCTP_SPI_CTRL_OPTS/{n;s/.*/ExecStop=\/usr\/bin\/mctp-vdm-util -c restart_notification -t 0/}' ${S}/systemd/system/mctp-spi-ctrl.service
}

