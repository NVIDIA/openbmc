do_install:append() {
    rm -f ${D}${systemd_system_unitdir}/mctpd.service
}

DEPENDS += "python3-pytest-native dbus-native"
SYSTEMD_SERVICE:${PN}:remove = "mctpd.service"