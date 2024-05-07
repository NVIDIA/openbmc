FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/bmcweb;protocol=https;branch=develop"
SRCREV = "da2af703dc3f2453e6598f20e75c075c9a190737"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"
EXTRA_OEMESON += "-Dredfish-new-powersubsystem-thermalsubsystem=enabled"
EXTRA_OEMESON += "-Dredfish-dbus-log=enabled"
EXTRA_OEMESON += "-Dupdate-service-task-timeout=5 -Dhttp-body-limit=300"
EXTRA_OEMESON += "-Dfirmware-image-limit=200"
EXTRA_OEMESON += "-Dbmcweb-logging=info"
EXTRA_OEMESON += "-Dinsecure-enable-redfish-query=enabled"

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
FILES:${PN}:append:hgx = " ${systemd_system_unitdir}/bmcweb.service.d/bmcweb-hgx.conf \
                            ${systemd_system_unitdir}/bmcweb.socket.d/bmcweb-socket-hgx.conf"

SYSTEMD_OVERRIDE:${PN} += "bmcweb-hgx.conf:bmcweb.service.d/bmcweb-hgx.conf"

do_install:append:hgx() {
    install -d ${D}${systemd_system_unitdir}/bmcweb.service.d
    install -m 0644 ${WORKDIR}/hgx/bmcweb-hgx.conf ${D}${systemd_system_unitdir}/bmcweb.service.d/
    install -d ${D}${systemd_system_unitdir}/bmcweb.socket.d
    install -m 0644 ${WORKDIR}/hgx/bmcweb-socket-hgx.conf ${D}${systemd_system_unitdir}/bmcweb.socket.d/
}

