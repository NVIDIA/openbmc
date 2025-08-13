EXTRA_OEMESON += "-Dlocal-eid=8"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI:append = " file://files/nsmd.service \
                 "

EXTRA_OEMESON:append = " -Dsystem-guid=enabled "
EXTRA_OEMESON:append = " -Daccelerator-dbus=disabled "
EXTRA_OEMESON:append = " -Dreset-metrics=enabled "

do_install:append() {
    install -D ${UNPACKDIR}/files/nsmd.service ${D}${base_libdir}/systemd/system/nsmd.service
}
