FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI:append = " file://files/nsmd.service \
                 "

EXTRA_OEMESON:append = " -Dsystem-guid=enabled "
EXTRA_OEMESON:append = " -Dgrace-spi-operations=enabled "
#EXTRA_OEMESON:append = " -Dgrace-spi-operations-raw-debug-dump=enabled "
EXTRA_OEMESON:append = " -Daccelerator-dbus=disabled "
EXTRA_OEMESON:append = " -Dreset-metrics=enabled "
EXTRA_OEMESON:append = " -Dnvidia-fpga-pcie-reference-clock-count=disabled"
EXTRA_OEMESON += "${@bb.utils.contains('DISTRO_FEATURES', 'mctp-inkernel', ' -Denable-in-kernel-mctp=enabled', '', d)}"

do_install:append() {
    install -D ${WORKDIR}/files/nsmd.service ${D}${base_libdir}/systemd/system/nsmd.service
}
