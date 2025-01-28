SUMMARY = "Rack Power Controller"
DESCRIPTION = "Rack Power Controller"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=424b4b48c3ba5f01f3b673daccb8ccd5"

SRC_URI = "git://github.com/NVIDIA/RackPowerController;protocol=https;branch=main"
SRCREV = "934cd0a1799d433bad8508c4eb6b5c16c2846c95"

inherit pkgconfig meson
inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = " \
    redis-plus-plus \
    yaml-cpp \
    nlohmann-json \
    phosphor-dbus-interfaces \
    sdbusplus \
    systemd \
"

S = "${WORKDIR}/git"

#INHIBIT_PACKAGE_STRIP = "1"
#INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

FILESEXTRAPATHS:append := ":${THISDIR}/files"

SYSDSVCS = " nvidia-rack-power-controller.service "

FILES:${PN}:append = " ${systemd_system_unitdir}/${SYSDSVCS}"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "${SYSDSVCS}"
