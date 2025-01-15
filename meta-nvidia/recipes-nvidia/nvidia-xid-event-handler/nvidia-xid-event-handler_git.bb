SUMMARY = "NVIDIA XID Event Handler"
DESCRIPTION = "NVIDIA XID over SMBPBI Event Handler"
HOMEPAGE = "https://gitlab-master.nvidia.com/dgx/bmc/openbmc"
PR = "r1"
PV = "0.1+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd

RDEPENDS:${PN}:append = " bash"

DEPENDS += "systemd"

# Using NVIDIA Gitlab URI for OpenBMC for now, please make sure your Gitlab key doesn't have a passphase.
# You could change the passphase to empty by 'ssh-keygen -p -f ~/.ssh/<your_gitlab_id_file>'
# This issue will be solved when we upstream all codes to github.
SRC_URI += "git://github.com/NVIDIA/nvidia-monitor-eventing;protocol=https;branch=develop"
SRCREV = "de8f7e9d47e4bd1ab53bb4df1a802d62b3071e1a"
S = "${WORKDIR}/git"

SVC_NAME = "nvidia-xid-event-handler.service"
APP_NAME = "nvidia-xid-event-handler"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "${SVC_NAME}"

FILES:${PN}:append = " ${bindir}/${APP_NAME}"
FILES:${PN}:append = " ${systemd_system_unitdir}/${SVC_NAME}"

SRC_URI:append = " file://${SVC_NAME}"

do_compile[noexec] = "1"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -d ${D}${bindir}
    install -m 0755 ${S}/tools/${APP_NAME} ${D}${bindir}/
    install -m 0644 ${WORKDIR}/${SVC_NAME} ${D}${systemd_system_unitdir}/
}
