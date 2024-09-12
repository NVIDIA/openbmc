SUMMARY = "NVIDIA Monitor Eventing Service"
DESCRIPTION = "NVIDIA Monitor Eventing Service"
HOMEPAGE = "https://gitlab-master.nvidia.com/dgx/bmc/nvidia-monitor-eventing"
PR = "r1"
PV = "0.1+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit meson pkgconfig
inherit systemd

DEPENDS += "nlohmann-json"
DEPENDS += "systemd"
DEPENDS += "sdbusplus ${PYTHON_PN}-sdbus++-native"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-logging"

EXTRA_OEMESON += "-Dtests=disabled"

# Using NVIDIA Gitlab URI for OpenBMC for now, please make sure your Gitlab key doesn't have a passphase.
# You could change the passphase to empty by 'ssh-keygen -p -f ~/.ssh/<your_gitlab_id_file>'
# This issue will be solved when we upstream all codes to github.
SRC_URI += "git://github.com/NVIDIA/nvidia-monitor-eventing;protocol=https;branch=develop"
SRCREV = "f6bb2333f956a1913be99d2f35038bb0a3590f5e"
S = "${WORKDIR}/git"

FILES:${PN}:append = " ${bindir}/monitor-eventingd"
FILES:${PN}:append = " ${libdir}/libeventing${SOLIBS}"
FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-monitor-eventing.service"
FILES:${PN}:append = " ${datadir}/mon_evt/*.json"
FILES:${PN}:append = " ${datadir}/*.conf"
FILES:${PN}:append = " ${datadir}/*.csv"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "nvidia-monitor-eventing.service"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://nvidia-monitor-eventing.service \
    file://mctp-vdm-util-wrapper \
    file://fpga_regtbl \
    "

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/nvidia-*.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${WORKDIR}/mctp-vdm-util-wrapper ${D}${bindir}/
    install -m 0755 ${WORKDIR}/fpga_regtbl ${D}${bindir}/
}

#
# Monitor Eventing Service memory watcher configuration
#

SRC_URI:append = " file://nvidia-monitor-eventing-memory-watcher.service"

SYSTEMD_SERVICE:${PN} += "nvidia-monitor-eventing-memory-watcher.service"

FILES:${PN}:append = " ${bindir}/monitor-eventing-memory-watcher"
FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-monitor-eventing-memory-watcher.service"
