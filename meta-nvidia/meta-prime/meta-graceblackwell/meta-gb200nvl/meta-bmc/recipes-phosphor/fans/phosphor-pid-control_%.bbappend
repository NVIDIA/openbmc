FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-pid-control;protocol=https;branch=develop"
SRCREV = "39a6aa52d7c722ea06cfe2a23063ca7cb5af7257"

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
    install -m 0755 ${UNPACKDIR}/fan-init.sh ${D}/${bindir}/fan-init.sh
    install -m 0755 ${UNPACKDIR}/fan-manual-speed.sh ${D}/${bindir}/fan-manual-speed.sh

    install -d ${D}${base_libdir}/systemd/system
    install -m 0644 ${UNPACKDIR}/fan-init.service ${D}${base_libdir}/systemd/system/fan-init.service
}

FILES:${PN}:append = " ${bindir}/fan-init.sh"
FILES:${PN}:append = " ${bindir}/fan-manual-speed.sh"
FILES:${PN}:append = " ${base_libdir}/systemd/system/fan-init.service"
