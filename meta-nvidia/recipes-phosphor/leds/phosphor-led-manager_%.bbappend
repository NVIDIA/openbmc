
SYSTEMD_SERVICE:${PN}:remove = "obmc-led-group-start@.service obmc-led-group-stop@.service"

do_install:append() {
    rm -f ${D}${base_libdir}/systemd/system/obmc-led-group-start@.service
    rm -f ${D}${base_libdir}/systemd/system/obmc-led-group-stop@.service
}
