SUMMARY = "NVIDIA GPIO Status Handler"
DESCRIPTION = "NVIDIA GPIO Status Handler"
HOMEPAGE = "https://gitlab-master.nvidia.com/dgx/bmc/nvidia-gpio-status-handler"
PR = "r1"
PV = "0.1+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit meson pkgconfig
inherit systemd

DEPENDS += "nlohmann-json"
DEPENDS += "systemd"
DEPENDS += "sdbusplus ${PYTHON_PN}-sdbus++-native"
DEPENDS += "phosphor-logging"
DEPENDS += "libgpiod"


# Using NVIDIA Gitlab URI for OpenBMC for now, please make sure your Gitlab key doesn't have a passphase.
# You could change the passphase to empty by 'ssh-keygen -p -f ~/.ssh/<your_gitlab_id_file>'
# This issue will be solved when we upstream all codes to github.
SRC_URI += "git://github.com/NVIDIA/nvidia-gpio-status-handler;protocol=https;branch=develop"
SRCREV = "e7e4c5831e821a0cf4caf9dd61e682d8e96d0ee1"
S = "${WORKDIR}/git"

SVC_NAME = "gpio-status-handler.service"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "${SVC_NAME}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

FILES:${PN}:append = " ${systemd_system_unitdir}/${SVC_NAME}"

SRC_URI:append = " file://${SVC_NAME}"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/${SVC_NAME} ${D}${systemd_system_unitdir}/
}


