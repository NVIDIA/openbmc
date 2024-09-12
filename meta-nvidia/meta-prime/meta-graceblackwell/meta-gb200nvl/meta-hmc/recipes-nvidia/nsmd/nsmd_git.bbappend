FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI:append = " file://files/nsmd.service \
                 "

do_install:append() {
    install -D ${WORKDIR}/files/nsmd.service ${D}${base_libdir}/systemd/system/nsmd.service
}
