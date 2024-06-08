SRC_URI = "git://github.com/NVIDIA/phosphor-pid-control;protocol=https;branch=develop"
SRCREV = "651f9a48fe7473df1ff4d24c4492ae5ef4f9eaf4"

inherit systemd


RDEPENDS:${PN} += "bash"
RDEPENDS:${PN} += "nvidia-event-logs"

do_install:append() {
    install -d ${D}${bindir}

    install -d ${D}${base_libdir}/systemd/system
}
