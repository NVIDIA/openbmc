# Override critical services to monitor
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
FILES:${PN}-bmc:append = " ${sysconfdir}/phosphor-service-monitor-default.json"
SRC_URI:append = " file://phosphor-service-monitor-default.json"
do_install:append() {
    install -d ${D}${sysconfdir}/phosphor-systemd-target-monitor
    install -m 0644 ${WORKDIR}/phosphor-service-monitor-default.json \
        ${D}${sysconfdir}/phosphor-systemd-target-monitor/
}

CHASSIS_DEFAULT_TARGETS:remove = " \
    obmc-chassis-poweron@{}.target.requires/obmc-power-start@{}.service \
    obmc-chassis-poweroff@{}.target.requires/obmc-power-stop@{}.service \
    obmc-chassis-poweroff@{}.target.requires/obmc-powered-off@{}.service \
    obmc-chassis-powerreset@{}.target.requires/phosphor-reset-chassis-on@{}.service \
    obmc-chassis-powerreset@{}.target.requires/phosphor-reset-chassis-running@{}.service \
"

PACKAGECONFIG:remove = "only-allow-boot-when-bmc-ready"
