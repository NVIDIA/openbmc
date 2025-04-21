SUMMARY = "SPDM Stack"
DESCRIPTION = "Implementation of the SPDM specifications"
PR = "r1"
PV = "1.0+git${SRCPV}"

inherit meson pkgconfig
inherit systemd

require spdm.inc

DEPENDS += "systemd"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-dbus-interfaces"
DEPENDS += "nlohmann-json"
DEPENDS += "cli11"
DEPENDS += "mbedtls"
DEPENDS += "libmctp"

S = "${WORKDIR}/git"

SYSTEMD_SERVICE:${PN} += "spdmd.service"

EXTRA_OEMESON = " \
        -Dtests=disabled \
        -Dfetch_serialnumber_from_responder=26 \
        "
