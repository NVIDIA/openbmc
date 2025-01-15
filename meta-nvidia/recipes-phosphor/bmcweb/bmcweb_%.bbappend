FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/bmcweb;protocol=https;branch=develop"
SRCREV = "bc0ceaeff40822f21d450108f17546469388a6e8"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"
EXTRA_OEMESON += "-Dredfish-new-powersubsystem-thermalsubsystem=enabled"
EXTRA_OEMESON += "-Dredfish-dbus-log=enabled"
EXTRA_OEMESON += "-Dupdate-service-task-timeout=5 -Dhttp-body-limit=300"
EXTRA_OEMESON += "-Dfirmware-image-limit=200"
EXTRA_OEMESON += "-Dbmcweb-logging=error"
EXTRA_OEMESON += "-Dinsecure-enable-redfish-query=enabled"
EXTRA_OEMESON += "-Dbmcweb-response-timeout=180"
EXTRA_OEMESON += "-Dbmcweb-chunking=enabled"
EXTRA_OEMESON += "-Drsyslog-client=enabled"

DEPENDS += "libpwquality"
RDEPENDS:${PN}-runtime += "libpwquality"

# add "redfish-hostiface" group
GROUPADD_PARAM:${PN}:append = ";redfish-hostiface"

SRC_URI:append:hgx = " file://hgx/bmcweb-hgx.conf \
                       file://hgx/bmcweb-socket-hgx.conf"
SRC_URI:append:hgxb = " file://hgxb/bmcweb-hgxb.conf \
                       file://hgxb/bmcweb-socket-hgxb.conf"
FILES:${PN}:append:hgx = " ${systemd_system_unitdir}/bmcweb.service.d/bmcweb-hgx.conf \
                            ${systemd_system_unitdir}/bmcweb.socket.d/bmcweb-socket-hgx.conf"
FILES:${PN}:append:hgxb = " ${systemd_system_unitdir}/bmcweb.service.d/bmcweb-hgxb.conf \
                            ${systemd_system_unitdir}/bmcweb.socket.d/bmcweb-socket-hgxb.conf"

SYSTEMD_OVERRIDE:${PN}:hgx += "bmcweb-hgx.conf:bmcweb.service.d/bmcweb-hgx.conf"
SYSTEMD_OVERRIDE:${PN}:hgxb += "bmcweb-hgxb.conf:bmcweb.service.d/bmcweb-hgxb.conf"

do_install:append:hgx() {
    install -d ${D}${systemd_system_unitdir}/bmcweb.service.d
    install -m 0644 ${WORKDIR}/hgx/bmcweb-hgx.conf ${D}${systemd_system_unitdir}/bmcweb.service.d/
    install -d ${D}${systemd_system_unitdir}/bmcweb.socket.d
    install -m 0644 ${WORKDIR}/hgx/bmcweb-socket-hgx.conf ${D}${systemd_system_unitdir}/bmcweb.socket.d/
}

do_install:append:hgxb() {
    install -d ${D}${systemd_system_unitdir}/bmcweb.service.d
    install -m 0644 ${WORKDIR}/hgxb/bmcweb-hgxb.conf ${D}${systemd_system_unitdir}/bmcweb.service.d/
    install -d ${D}${systemd_system_unitdir}/bmcweb.socket.d
    install -m 0644 ${WORKDIR}/hgxb/bmcweb-socket-hgxb.conf ${D}${systemd_system_unitdir}/bmcweb.socket.d/
}
