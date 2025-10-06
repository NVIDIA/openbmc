FILESEXTRAPATHS:prepend := "${THISDIR}/:"
SRC_URI = "git://github.com/NVIDIA/mctp;protocol=https;branch=develop \
           "
SRCREV = "2558d6d1537aabdf8bfc02f3bcd936fe0ee54af4"
SRC_URI:append = "file://mctp.rules \
                  file://mctpd.service "

SYSTEMD_SERVICE:${PN}:append = " mctpd.service "
FILES:${PN} += "\
                   ${nonarch_base_libdir}/udev/rules.d/mctp.rules \
                   ${nonarch_base_libdir}/systemd/system/mctpd.service \
"
DEPENDS += "python3-pytest-native dbus-native"

do_install:append() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${UNPACKDIR}/mctp.rules ${D}${sysconfdir}/udev/rules.d
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctpd.service
    install -m 0644 ${UNPACKDIR}/mctpd.service  ${D}${nonarch_base_libdir}/systemd/system/
}
