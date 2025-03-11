FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-buttons;protocol=https;branch=develop"
SRCREV = "89df433bb57cc84b76c933006683ce6040d82067"
SRC_URI += "file://gpio_defs.json"

inherit meson pkgconfig systemd

DEPENDS += "libgpiod"

do_install:append() {
        mkdir -p ${D}/etc/default/obmc/gpio/
        install -m 0644 ${WORKDIR}/gpio_defs.json ${D}/etc/default/obmc/gpio/gpio_defs.json
}
