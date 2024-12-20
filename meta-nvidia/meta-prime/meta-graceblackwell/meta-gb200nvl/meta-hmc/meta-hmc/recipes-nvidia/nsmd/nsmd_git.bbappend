FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI:append = " file://files/nsmd.service \
                 "

EXTRA_OEMESON:append = " -Dsystem-guid=enabled "
EXTRA_OEMESON:append = " -Daccelerator-dbus=disabled "

do_install:append() {
    install -D ${WORKDIR}/files/nsmd.service ${D}${base_libdir}/systemd/system/nsmd.service
}
