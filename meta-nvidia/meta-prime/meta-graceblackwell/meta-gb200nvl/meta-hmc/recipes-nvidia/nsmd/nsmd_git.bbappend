FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI:append = " file://files/nsmd.service \
                 "

EXTRA_OEMESON:append = " -Dsystem-guid=enabled "
EXTRA_OEMESON:append = " -Dgrace-spi-operations=enabled "
#EXTRA_OEMESON:append = " -Dgrace-spi-operations-raw-debug-dump=enabled "
EXTRA_OEMESON:append = " -Daccelerator-dbus=disabled "
EXTRA_OEMESON:append = " -Dreset-metrics=enabled "
EXTRA_OEMESON:append = " -Dnvidia-fpga-pcie-reference-clock-count=disabled"
EXTRA_OEMESON:append = " -Denable-in-kernel-mctp=enabled "

do_install:append() {
    install -D ${UNPACKDIR}/files/nsmd.service ${D}${base_libdir}/systemd/system/nsmd.service
}
