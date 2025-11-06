SUMMARY = "Nvidia System Management Daemon"
DESCRIPTION = "Nvidia System Management Daemon"

PR = "r1"
PV = "0.1+git${SRCPV}"

LICENSE = "CLOSED"

inherit meson pkgconfig obmc-phosphor-systemd

DEPENDS += "function2"
DEPENDS += "systemd"
DEPENDS += "sdbusplus"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-dbus-interfaces"
DEPENDS += "phosphor-logging"
DEPENDS += "nlohmann-json"
DEPENDS += "cli11"
DEPENDS += "libmctp"
DEPENDS += "nvidia-tal"
DEPENDS += "googletest"

EXTRA_OEMESON:hgxb += "-Dmctp-eid-filtering=true"
EXTRA_OEMESON += " \
    -Denable-in-kernel-mctp=enabled \
    -Dtests=disabled \
"

SRC_URI = "git://github.com/NVIDIA/nsmd;protocol=https;branch=develop"
SRCREV = "5749f2053f5a0588d9ae2b0728241dcfcb10bc02"
S = "${WORKDIR}/git"

SYSTEMD_SERVICE:${PN} = "nsmd.service"
FILES:${PN}:append = " ${datadir}/libnsm/instance-db/default"
