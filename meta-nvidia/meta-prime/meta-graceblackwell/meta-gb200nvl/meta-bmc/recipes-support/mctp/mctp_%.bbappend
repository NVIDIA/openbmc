FILESEXTRAPATHS:prepend := "${THISDIR}/:"
SRC_URI = "git://github.com/NVIDIA/mctp;protocol=https;branch=develop \
           "
SRCREV = "70c0e3f5daa6dd9cd7b296f371ae3b21a5379e88"
SRC_URI:append = "file://mctp.rules \
                  file://mctpd.service \
                  file://mctp_cx7_endpoints.service "

SYSTEMD_SERVICE:${PN}:append = " mctpd.service mctp_cx7_endpoints.service "
FILES:${PN} += "\
                   ${nonarch_base_libdir}/udev/rules.d/mctp.rules \
                   ${nonarch_base_libdir}/systemd/system/mctpd.service \
                   ${nonarch_base_libdir}/systemd/system/mctp_cx7_endpoints.service \
"
DEPENDS += "python3-pytest-native dbus-native"

do_install:append() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${UNPACKDIR}/mctp.rules ${D}${sysconfdir}/udev/rules.d
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctpd.service
    install -m 0644 ${UNPACKDIR}/mctpd.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${UNPACKDIR}/mctp_cx7_endpoints.service  ${D}${nonarch_base_libdir}/systemd/system/
}
