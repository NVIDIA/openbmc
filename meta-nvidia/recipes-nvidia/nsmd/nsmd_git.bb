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

#EXTRA_OEMESON = "-Dtests=disabled"
EXTRA_OEMESON:hgxb += "-Dmctp-eid0-filtering=true"

SRC_URI = "git://github.com/NVIDIA/nsmd;protocol=https;branch=develop"
SRCREV = "85facbbc992bb4672d20ebd37f021d76c2b44e75"
S = "${WORKDIR}/git"

SYSTEMD_SERVICE:${PN} = "nsmd.service"
FILES:${PN}:append = " ${datadir}/libnsm/instance-db/default"
