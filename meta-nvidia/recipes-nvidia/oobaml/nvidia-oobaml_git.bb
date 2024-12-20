SUMMARY = "NVIDIA OOB AML Module"
DESCRIPTION = "NVIDIA OOB AML Module"
HOMEPAGE = "https://gitlab-master.nvidia.com/dgx/bmc/nvidia-oobaml"
PR = "r1"
PV = "0.1+git${SRCPV}"

# Need correct license info here before upstream.
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit meson pkgconfig
inherit systemd

DEPENDS += "autoconf-archive-native"
DEPENDS += "nlohmann-json"
DEPENDS += "systemd"
DEPENDS += "sdbusplus ${PYTHON_PN}-sdbus++-native"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-logging"
# Gpio status monitor dependency:
DEPENDS += "libgpiod"

EXTRA_OEMESON += "-Dtests=disabled"

# Using NVIDIA Gitlab URI for OpenBMC for now, please make sure your Gitlab key doesn't have a passphase.
# You could change the passphase to empty by 'ssh-keygen -p -f ~/.ssh/<your_gitlab_id_file>'
# This issue will be solved when we upstream all codes to github.
SRC_URI += "git://github.com/NVIDIA/nvidia-oobaml;protocol=https;branch=develop"
SRCREV = "c089083fe31ace1f480f9b7cde81fcc3eb540175"
S = "${WORKDIR}/git"

FILES:${PN}:append = " ${bindir}/oobamld"
FILES:${PN}:append = " ${libdir}/liboobaml${SOLIBS}"
FILES:${PN}-dev:append = " ${includedir}/*.hpp"
FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-oobaml.service"
FILES:${PN}:append = " ${datadir}/oobaml/*.json"
FILES:${PN}:append = " ${datadir}/*.csv"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "nvidia-oobaml.service"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://nvidia-oobaml.service \
    "

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/nvidia-*.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/xyz.openbmc_project.GpioStatusHandler.service ${D}${systemd_system_unitdir}/
}

#
# Gpio status monitor configuration
#

SRC_URI:append = " file://xyz.openbmc_project.GpioStatusHandler.service"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.GpioStatusHandler.service"

FILES:${PN}:append = " ${bindir}/gpio-status-handlerd"
FILES:${PN}:append = " ${systemd_system_unitdir}/xyz.openbmc_project.GpioStatusHandler.service"

