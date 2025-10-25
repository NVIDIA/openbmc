FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "git://github.com/NVIDIA/phosphor-led-manager;protocol=https;branch=develop"
SRCREV = "997165b66aeeb21816c71bd4b59fdf962df571b4"

SRC_URI:append = " file://power-led-controller.service \
                   file://power-led-config-default.json \
                   file://power-led-config-dc-scm.json \
                   file://update-power-led-config.sh \
                   "

FILES:${PN} += "${bindir}/power-led-controller"
SYSTEMD_SERVICE:${PN} = "power-led-controller.service"

do_install:append() {
        install -d ${D}${base_libdir}/systemd/system
        install -m 0644 ${UNPACKDIR}/power-led-controller.service ${D}${base_libdir}/systemd/system/
        install -m 0644 ${UNPACKDIR}/power-led-config-default.json ${D}/usr/share/phosphor-led-manager/power-led-config-default.json
        install -m 0644 ${UNPACKDIR}/power-led-config-dc-scm.json ${D}/usr/share/phosphor-led-manager/power-led-config-dc-scm.json
        install -m 0755 ${UNPACKDIR}/update-power-led-config.sh ${D}/usr/bin/update-power-led-config.sh
}

FILES:${PN}:append = " ${base_libdir}/systemd/system/power-led-controller.service "
