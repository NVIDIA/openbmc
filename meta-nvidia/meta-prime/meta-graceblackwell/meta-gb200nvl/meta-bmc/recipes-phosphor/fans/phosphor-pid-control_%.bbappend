FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-pid-control;protocol=https;branch=develop"
SRCREV = "6b1912f9b5f2a1386169fb42fff1a48f911210a6"

inherit systemd

SYSTEMD_SERVICE:${PN}:append = " fan-init.service"

SRC_URI:append = " file://fan-init.service \
                   file://fan-init.sh \
                   file://fan-manual-speed.sh \
                 "

RDEPENDS:${PN} += "bash"
RDEPENDS:${PN} += "nvidia-event-logs"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/fan-init.sh ${D}/${bindir}/fan-init.sh
    install -m 0755 ${WORKDIR}/fan-manual-speed.sh ${D}/${bindir}/fan-manual-speed.sh

    install -d ${D}${base_libdir}/systemd/system
    install -m 0644 ${WORKDIR}/fan-init.service ${D}${base_libdir}/systemd/system/fan-init.service
}

FILES:${PN}:append = " ${bindir}/fan-init.sh"
FILES:${PN}:append = " ${bindir}/fan-manual-speed.sh"
FILES:${PN}:append = " ${base_libdir}/systemd/system/fan-init.service"
