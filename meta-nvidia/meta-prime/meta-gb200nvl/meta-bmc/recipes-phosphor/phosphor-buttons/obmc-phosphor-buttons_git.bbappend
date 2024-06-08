FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-buttons;protocol=https;branch=develop"
SRCREV = "4a71e8acc899b82d71b3757a141db784b0e09a10"
SRC_URI += "file://gpio_defs.json"

inherit meson pkgconfig systemd

DEPENDS += "libgpiod"

do_install:append() {
        mkdir -p ${D}/etc/default/obmc/gpio/
        install -m 0644 ${WORKDIR}/gpio_defs.json ${D}/etc/default/obmc/gpio/gpio_defs.json
}
