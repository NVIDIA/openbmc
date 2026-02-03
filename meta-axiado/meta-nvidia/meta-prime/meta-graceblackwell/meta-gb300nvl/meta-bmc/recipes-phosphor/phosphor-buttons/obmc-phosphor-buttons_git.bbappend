FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-buttons;protocol=https;branch=develop"
SRCREV = "f917af675a78ef073eff6e433a30af87b5988b7f"
SRC_URI += "file://gpio_defs_default.json \
            file://gpio_defs_dc_scm.json \
            file://xyz.openbmc_project.Chassis.Buttons.service \
            file://update-button-config.sh"

inherit meson pkgconfig systemd

DEPENDS += "libgpiod"
RDEPENDS:${PN} += "bash"

do_install:append() {
        mkdir -p ${D}/etc/default/obmc/gpio/
        install -m 0644 ${UNPACKDIR}/gpio_defs_default.json ${D}/etc/default/obmc/gpio/gpio_defs_default.json
        install -m 0644 ${UNPACKDIR}/gpio_defs_dc_scm.json ${D}/etc/default/obmc/gpio/gpio_defs_dc_scm.json
        install -m 0644 ${UNPACKDIR}/xyz.openbmc_project.Chassis.Buttons.service ${D}/usr/lib/systemd/system/xyz.openbmc_project.Chassis.Buttons.service
        install -m 0755 ${UNPACKDIR}/update-button-config.sh ${D}/usr/bin/update-button-config.sh
}
