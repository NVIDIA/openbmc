FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://rsyslog.conf \
    file://hmc_rsyslog.logrotate \
    file://rotate-event-logs.service \
    file://rotate-event-logs.sh \
    file://rsyslog-override.conf \
    file://server.conf \
    file://hmc.conf \
"

FILES:${PN} += "${systemd_system_unitdir}/rsyslog.service.d/rsyslog-override.conf"


do_install:append() {
        install -m 0644 ${WORKDIR}/rotate-event-logs.service ${D}${systemd_system_unitdir}
        install -d ${D}${systemd_system_unitdir}/rsyslog.service.d
        install -m 0644 ${WORKDIR}/rsyslog-override.conf \
                        ${D}${systemd_system_unitdir}/rsyslog.service.d/rsyslog-override.conf
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/rotate-event-logs.sh ${D}/${bindir}/rotate-event-logs.sh
        cat ${WORKDIR}/hmc_rsyslog.logrotate >> ${D}/etc/logrotate.d/logrotate.rsyslog
        install -m 0644 -D ${WORKDIR}/hmc.conf ${D}${sysconfdir}/rsyslog.d/hmc.conf
}

SYSTEMD_SERVICE:${PN} += " rotate-event-logs.service"