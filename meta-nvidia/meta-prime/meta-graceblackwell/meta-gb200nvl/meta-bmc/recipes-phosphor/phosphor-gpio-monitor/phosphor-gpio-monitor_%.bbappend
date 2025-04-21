FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRCREV = "0c60faaa0b53dad6561b95e66c0a601e442aeecf"

inherit systemd

SRC_URI:append = " \
           file://phosphor-multi-gpio-monitor.json \
           file://phosphor-multi-gpio-monitor.service \
           file://power-fault@.service \
           file://fan-fail@.service \
           file://overtemp@.service \
           file://error_log.sh \
           "
SRC_URI:append:gb200nvl-bmc-ut3 = " file://phosphor-multi-gpio-monitor-ut3.json "

RDEPENDS:${PN} += "bash sbiosbootaccess phosphor-gpio-monitor-monitor "

do_install:append() {
        mkdir -p ${D}/usr/share/phosphor-gpio-monitor/
        install -m 0644 ${WORKDIR}/phosphor-multi-gpio-monitor.json ${D}/usr/share/phosphor-gpio-monitor/phosphor-multi-gpio-monitor.json

        install -d ${D}${base_libdir}/systemd/system
        install -m 0644 ${WORKDIR}/phosphor-multi-gpio-monitor.service ${D}${base_libdir}/systemd/system/phosphor-multi-gpio-monitor.service
        install -m 0644 ${WORKDIR}/power-fault@.service ${D}${base_libdir}/systemd/system/power-fault@.service
        install -m 0644 ${WORKDIR}/fan-fail@.service ${D}${base_libdir}/systemd/system/fan-fail@.service
        install -m 0644 ${WORKDIR}/overtemp@.service ${D}${base_libdir}/systemd/system/overtemp@.service
        install -m 0755 ${WORKDIR}/error_log.sh ${D}/${bindir}/
}

do_install:append:gb200nvl-bmc-ut3() {
		install -m 0644 ${WORKDIR}/phosphor-multi-gpio-monitor-ut3.json ${D}/usr/share/phosphor-gpio-monitor/phosphor-multi-gpio-monitor.json
}


FILES:${PN}-monitor:append= " \
         ${base_libdir}/systemd/system/phosphor-multi-gpio-monitor.service \
         ${base_libdir}/systemd/system/power-fault@.service \
         ${base_libdir}/systemd/system/fan-fail@.service \
         ${base_libdir}/systemd/system/overtemp@.service \
        "
