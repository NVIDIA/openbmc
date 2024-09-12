FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/bmcweb;protocol=https;branch=develop"
SRCREV = "e9431b2f442d5423178d09d373b0d26713ad8e20"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"
EXTRA_OEMESON += "-Dredfish-new-powersubsystem-thermalsubsystem=enabled"
EXTRA_OEMESON += "-Dredfish-dbus-log=enabled"
EXTRA_OEMESON += "-Dupdate-service-task-timeout=5 -Dhttp-body-limit=300"
EXTRA_OEMESON += "-Dfirmware-image-limit=200"
EXTRA_OEMESON += "-Dbmcweb-logging=error"
EXTRA_OEMESON += "-Dinsecure-enable-redfish-query=enabled"
EXTRA_OEMESON += "-Dbmcweb-response-timeout=180"
EXTRA_OEMESON += "-Dbmcweb-chunking=enabled"

def get_oeconf(d, policy_var, meson_var):
    val = d.getVar(policy_var , True)
    if val is None:
        return ""
    if not val:
        return ""
    rval = " -D" + meson_var;
    rval += "="
    rval += val
    return rval

EXTRA_OEMESON += "${@get_oeconf(d, 'MIN_UCASE_CHRS', 'min-ucase-characters')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'MIN_LCASE_CHRS', 'min-lcase-characters')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'MIN_DIGITS', 'min-digits')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'MIN_SPEC_CHRS', 'min-special-characters')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'MIN_PASSWORD_LENGTH', 'min-password-length')}"

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
