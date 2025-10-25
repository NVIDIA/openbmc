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
DEPENDS += "nvidia-tal"
RDEPENDS:${PN} += "curl"

EXTRA_OEMESON += "-Dtests=disabled"

SVC_NAME = "nvidia-monitor-eventing"

# Using NVIDIA Gitlab URI for OpenBMC for now, please make sure your Gitlab key doesn't have a passphase.
# You could change the passphase to empty by 'ssh-keygen -p -f ~/.ssh/<your_gitlab_id_file>'
# This issue will be solved when we upstream all codes to github.
SRC_URI += "git://github.com/NVIDIA/nvidia-monitor-eventing;protocol=https;branch=develop"
SRCREV = "847b48ba51d91341c241d6e8599c416d78b6c060"
S = "${WORKDIR}/git"

FILES:${PN}:append = " ${bindir}/monitor-eventingd"
FILES:${PN}:append = " ${libdir}/libeventing${SOLIBS}"
FILES:${PN}:append = " ${systemd_system_unitdir}/${SVC_NAME}.service"
FILES:${PN}:append = " ${systemd_system_unitdir}/${SVC_NAME}.service.d/*.conf"
FILES:${PN}:append = " ${datadir}/mon_evt/*.json"
FILES:${PN}:append = " ${datadir}/*.conf"
FILES:${PN}:append = " ${datadir}/*.csv"
FILES:${PN}:append = " ${datadir}/*.profile"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "${SVC_NAME}.service"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://${SVC_NAME}.service \
    file://mctp-vdm-util-wrapper \
    file://fpga_regtbl \
    "

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/nvidia-*.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${UNPACKDIR}/mctp-vdm-util-wrapper ${D}${bindir}/
    install -m 0755 ${UNPACKDIR}/fpga_regtbl ${D}${bindir}/
}

python do_validate_json() {
    import json
    import glob
    import os

    json_files = glob.glob(os.path.join(d.getVar('WORKDIR'), '*.json'))
    bb.note(f"json files: {json_files}")
    for file_path in json_files:
        try:
            with open(file_path, 'r') as f:
                json.load(f)
            bb.note(f"{file_path} is a valid JSON file.")
        except json.JSONDecodeError as e:
            bb.fatal(f"Invalid JSON file: {file_path}. Error: {e}")
}

addtask validate_json after do_unpack before do_compile


#
# Monitor Eventing Service memory watcher configuration
#

SRC_URI:append = " file://nvidia-monitor-eventing-memory-watcher.service"

SYSTEMD_SERVICE:${PN} += "nvidia-monitor-eventing-memory-watcher.service"

FILES:${PN}:append = " ${bindir}/monitor-eventing-memory-watcher"
FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-monitor-eventing-memory-watcher.service"
