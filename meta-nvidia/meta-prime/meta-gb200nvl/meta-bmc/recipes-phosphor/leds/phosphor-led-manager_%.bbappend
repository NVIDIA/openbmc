FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "git://github.com/NVIDIA/phosphor-led-manager;protocol=https;branch=develop"
SRCREV = "c590939b4950c3faf13d2b674335a371aeba18ce"

SRC_URI:append = " file://power-led-controller.service \
                   file://power-led-config.json \
                   "

FILES:${PN} += "${bindir}/power-led-controller"
SYSTEMD_SERVICE:${PN} = "power-led-controller.service"

do_install:append() {
        install -d ${D}${base_libdir}/systemd/system
        install -m 0644 ${WORKDIR}/power-led-controller.service ${D}${base_libdir}/systemd/system/
        install -m 0644 ${WORKDIR}/power-led-config.json ${D}/usr/share/phosphor-led-manager/power-led-config.json
}

FILES:${PN}:append = " ${base_libdir}/systemd/system/power-led-controller.service "
