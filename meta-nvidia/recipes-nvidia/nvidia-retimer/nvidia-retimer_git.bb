#
# TODO Copyright info.
#
SUMMARY = "NVIDIA Retimer"
DESCRIPTION = "NVIDIA Retimer"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

inherit meson pkgconfig obmc-phosphor-systemd

S = "${WORKDIR}/git"

SRC_URI = "git://github.com/NVIDIA/nvidia-retimer;protocol=https;branch=Core-24.09-1_br"
SRCREV = "8503e5746f98db34fa5621ff7fbf74c008e644d5"


PV = "0.1+git${SRCPV}"

EXTRA_OEMESON = "-Dtests=disabled"
SYSTEMD_SERVICE:${PN} = "nvidia-hashcompute-retimer.service"

DEPENDS = " \
         phosphor-logging \
         phosphor-dbus-interfaces \
         sdbusplus \
         fmt \
         i2c-tools \
         sdeventplus \
         openssl \
         nlohmann-json \
         "


do_install:append() {
        install -d ${D}${includedir}
        install -m 0755 ${S}/inventory/rt_util.hpp ${D}${includedir}/
}
