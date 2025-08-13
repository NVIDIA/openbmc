FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-buttons;protocol=https;branch=develop"
SRCREV = "f917af675a78ef073eff6e433a30af87b5988b7f"
SRC_URI += "file://gpio_defs.json"

inherit meson pkgconfig systemd

DEPENDS += "libgpiod"

do_install:append() {
        mkdir -p ${D}/etc/default/obmc/gpio/
        install -m 0644 ${UNPACKDIR}/gpio_defs.json ${D}/etc/default/obmc/gpio/gpio_defs.json
}
