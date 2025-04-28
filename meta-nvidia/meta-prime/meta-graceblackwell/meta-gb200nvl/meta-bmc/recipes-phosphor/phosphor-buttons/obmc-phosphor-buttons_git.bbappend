FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-buttons;protocol=https;branch=Core-24.09-1_br"
SRCREV = "e0f6b8cf429fc8c9c8fe8de6a00fa26234aad72e"
SRC_URI += "file://gpio_defs.json"

inherit meson pkgconfig systemd

DEPENDS += "libgpiod"

do_install:append() {
        mkdir -p ${D}/etc/default/obmc/gpio/
        install -m 0644 ${WORKDIR}/gpio_defs.json ${D}/etc/default/obmc/gpio/gpio_defs.json
}
