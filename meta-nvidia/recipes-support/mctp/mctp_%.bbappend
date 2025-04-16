do_install:append() {
    rm -f ${D}${systemd_system_unitdir}/mctpd.service
}

SYSTEMD_SERVICE:${PN}:remove = "mctpd.service"