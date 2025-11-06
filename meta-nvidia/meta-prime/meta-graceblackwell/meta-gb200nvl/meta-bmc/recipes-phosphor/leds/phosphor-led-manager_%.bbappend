FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "git://github.com/NVIDIA/phosphor-led-manager;protocol=https;branch=develop"
SRCREV = "b706ea56442d74dde28f262cb8db3d93c59e8c73"

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
