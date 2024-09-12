FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRCREV = "0c60faaa0b53dad6561b95e66c0a601e442aeecf"

inherit systemd

SRC_URI:append = " \
           file://phosphor-multi-gpio-monitor.json \
           file://phosphor-multi-gpio-monitor.service \
           "

RDEPENDS:${PN} += "bash sbiosbootaccess phosphor-gpio-monitor-monitor "

do_install:append() {
        mkdir -p ${D}/usr/share/phosphor-gpio-monitor/
        install -m 0644 ${WORKDIR}/phosphor-multi-gpio-monitor.json ${D}/usr/share/phosphor-gpio-monitor/phosphor-multi-gpio-monitor.json

        install -d ${D}${base_libdir}/systemd/system
        install -m 0644 ${WORKDIR}/phosphor-multi-gpio-monitor.service ${D}${base_libdir}/systemd/system/phosphor-multi-gpio-monitor.service
}

FILES:${PN}-monitor:append= " \
         ${base_libdir}/systemd/system/phosphor-multi-gpio-monitor.service \
        "
