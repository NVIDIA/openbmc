SUMMARY = "NVIDIA Power Manager"
DESCRIPTION = "NVIDIA Power Manager Daemon"

# NVIDIA Power Manager Daemon is used to monitor the PSU's/Power in the NVIDIA datacenter systems.

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

inherit meson systemd pkgconfig
S = "${WORKDIR}/git"

SRC_URI = "git://github.com/NVIDIA/nvidia-power-manager;protocol=https;branch=develop"
SRCREV = "39418a653017b7b3fba0bc4623bc9b57b20a6a44"

DEPENDS = " \
         phosphor-logging \
         phosphor-dbus-interfaces \
         sdbusplus \
         fmt \
         i2c-tools \
         sdeventplus \
         gtest \
         gmock \
         "
DEPENDS += "nlohmann-json"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "nvidia-power-supply.service nvidia-cpld.service nvidia-psu-monitor.service nvidia-power-manager.service"

PV = "0.1+git${SRCPV}"

EXTRA_OEMESON = " \
    -Dtests=disabled\
"
