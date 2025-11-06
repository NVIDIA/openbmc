FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/bmcweb;protocol=https;branch=develop"
SRCREV = "09a40db8e5d48947b38cacb6c32d2307ae778c6a"

EXTRA_OEMESON += "-Dredfish-new-powersubsystem-thermalsubsystem=enabled"
PACKAGECONFIG += "redfish-dbus-log"
PACKAGECONFIG += "redfish-dump-log"
PACKAGECONFIG += "redfish-bmc-journal"
EXTRA_OEMESON += "-Dupdate-service-task-timeout=5 -Dhttp-body-limit=300"
EXTRA_OEMESON += "-Dfirmware-image-limit=200"
EXTRA_OEMESON += "-Dbmcweb-logging=error"
EXTRA_OEMESON += "-Dinsecure-enable-redfish-query=enabled"
EXTRA_OEMESON += "-Dhttp-response-timeout=180"
EXTRA_OEMESON += "-Dhttp-chunking=enabled"
EXTRA_OEMESON += "-Drsyslog-client=enabled"

DEPENDS += "libpwquality"
RDEPENDS:${PN}-runtime += "libpwquality"

# add "redfish-hostiface" group
GROUPADD_PARAM:${PN}:append = ";redfish-hostiface"

SRC_URI:append:hgx = " file://hgx/bmcweb-hgx.conf \
                       file://hgx/bmcweb-socket-hgx.conf"
SRC_URI:append:hgxb = " file://hgxb/bmcweb-hgxb.conf \
                       file://hgxb/bmcweb-socket-hgxb.conf"
SRC_URI:append:hgxb300 = " file://hgxb300/bmcweb-hgxb300.conf \
                           file://hgxb300/bmcweb-socket-hgxb300.conf"
SRC_URI:append:hgxr = " file://hgxr/bmcweb-hgxr.conf \
                        file://hgxr/bmcweb-socket-hgxr.conf"
FILES:${PN}:append:hgx = " ${systemd_system_unitdir}/bmcweb.service.d/bmcweb-hgx.conf \
                            ${systemd_system_unitdir}/bmcweb.socket.d/bmcweb-socket-hgx.conf"
FILES:${PN}:append:hgxb = " ${systemd_system_unitdir}/bmcweb.service.d/bmcweb-hgxb.conf \
                            ${systemd_system_unitdir}/bmcweb.socket.d/bmcweb-socket-hgxb.conf"
FILES:${PN}:append:hgxb300 = " ${systemd_system_unitdir}/bmcweb.service.d/bmcweb-hgxb300.conf \
                               ${systemd_system_unitdir}/bmcweb.socket.d/bmcweb-socket-hgxb300.conf"
FILES:${PN}:append:hgxr = " ${systemd_system_unitdir}/bmcweb.service.d/bmcweb-hgxr.conf \
                            ${systemd_system_unitdir}/bmcweb.socket.d/bmcweb-socket-hgxr.conf"

SYSTEMD_OVERRIDE:${PN}:hgx += "bmcweb-hgx.conf:bmcweb.service.d/bmcweb-hgx.conf"
SYSTEMD_OVERRIDE:${PN}:hgxb += "bmcweb-hgxb.conf:bmcweb.service.d/bmcweb-hgxb.conf"
SYSTEMD_OVERRIDE:${PN}:hgxb300 += "bmcweb-hgxb.conf:bmcweb.service.d/bmcweb-hgxb300.conf"
SYSTEMD_OVERRIDE:${PN}:hgxr += "bmcweb-hgxr.conf:bmcweb.service.d/bmcweb-hgxr.conf"

DEPENDS += " \
    phosphor-logging \
    phosphor-dbus-interfaces \
    sdbusplus \
"

do_install:append:hgx() {
    install -d ${D}${systemd_system_unitdir}/bmcweb.service.d
    install -m 0644 ${UNPACKDIR}/hgx/bmcweb-hgx.conf ${D}${systemd_system_unitdir}/bmcweb.service.d/
    install -d ${D}${systemd_system_unitdir}/bmcweb.socket.d
    install -m 0644 ${UNPACKDIR}/hgx/bmcweb-socket-hgx.conf ${D}${systemd_system_unitdir}/bmcweb.socket.d/
}

do_install:append:hgxb() {
    install -d ${D}${systemd_system_unitdir}/bmcweb.service.d
    install -m 0644 ${UNPACKDIR}/hgxb/bmcweb-hgxb.conf ${D}${systemd_system_unitdir}/bmcweb.service.d/
    install -d ${D}${systemd_system_unitdir}/bmcweb.socket.d
    install -m 0644 ${UNPACKDIR}/hgxb/bmcweb-socket-hgxb.conf ${D}${systemd_system_unitdir}/bmcweb.socket.d/
}

do_install:append:hgxb300() {
    install -d ${D}${systemd_system_unitdir}/bmcweb.service.d
    install -m 0644 ${UNPACKDIR}/hgxb300/bmcweb-hgxb300.conf ${D}${systemd_system_unitdir}/bmcweb.service.d/
    install -d ${D}${systemd_system_unitdir}/bmcweb.socket.d
    install -m 0644 ${UNPACKDIR}/hgxb300/bmcweb-socket-hgxb300.conf ${D}${systemd_system_unitdir}/bmcweb.socket.d/
}

do_install:append:hgxr() {
    install -d ${D}${systemd_system_unitdir}/bmcweb.service.d
    install -m 0644 ${UNPACKDIR}/hgxr/bmcweb-hgxr.conf ${D}${systemd_system_unitdir}/bmcweb.service.d/
    install -d ${D}${systemd_system_unitdir}/bmcweb.socket.d
    install -m 0644 ${UNPACKDIR}/hgxr/bmcweb-socket-hgxr.conf ${D}${systemd_system_unitdir}/bmcweb.socket.d/
}
