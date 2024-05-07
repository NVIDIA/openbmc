FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-pid-control;protocol=https;branch=develop"
SRCREV = "f4fb5e7cc5fcfd3f56b3bac5288ec3c529e7fe3d"

inherit systemd
SYSTEMD_SERVICE:${PN}:append = " fan-boot-control.service"


SRC_URI:append = " file://fan-boot-control.service \
                   file://fan-default-speed.sh \
                 "

RDEPENDS:${PN} += "bash"
RDEPENDS:${PN} += "nvidia-event-logs"

do_install:append() {

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/fan-default-speed.sh ${D}/${bindir}/fan-default-speed.sh

    install -d ${D}${base_libdir}/systemd/system
    install -m 0644 ${WORKDIR}/fan-boot-control.service ${D}${base_libdir}/systemd/system/fan-boot-control.service

}

FILES:${PN}:append = " ${bindir}/fan-default-speed.sh"
FILES:${PN}:append = " ${base_libdir}/systemd/system/fan-boot-control.service"
