SUMMARY = "NVIDIA Cpld Manager"
DESCRIPTION = "NVIDIA Cpld Manager Daemon"

PR = "r1"
PV = "0.1+git${SRCPV}"

# Need correct license info here before upstream.
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit meson systemd pkgconfig
S = "${WORKDIR}/git"

SRC_URI = "git://github.com/NVIDIA/nvidia-cpld-manager;protocol=https;branch=develop"
SRCREV = "2c0550708207ad7851e81bc8633da852529cb2d5"

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
SYSTEMD_SERVICE:${PN} = "nvidia-cpld.service"

EXTRA_OEMESON = " \ 
    -Dtests=disabled\
    "
