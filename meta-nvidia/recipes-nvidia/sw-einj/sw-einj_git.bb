SUMMARY = "NVIDIA Software Error Injection"
DESCRIPTION = "Provides a framework for Error Injection by software with no hardware interaction"
HOMEPAGE = ""
PR = "r1"
PV = "0.1+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit meson pkgconfig
inherit systemd

DEPENDS += "nlohmann-json"
DEPENDS += "sdbusplus ${PYTHON_PN}-sdbus++-native"
DEPENDS += "sdeventplus"
DEPENDS += "curl"
DEPENDS += "cli11"
RDEPENDS:${PN} = "bash"

EXTRA_OEMESON += "-Dtests=disabled"

# Using NVIDIA Gitlab URI for OpenBMC for now, please make sure your Gitlab key doesn't have a passphase.
# You could change the passphase to empty by 'ssh-keygen -p -f ~/.ssh/<your_gitlab_id_file>'
# This issue will be solved when we upstream all codes to github.

SRC_URI += "git://github.com/NVIDIA/software-error-injection;protocol=https;branch=develop"
SRCREV = "1766f0d02f160080d41a86dd7174e75a3ebcd2e8"

S = "${WORKDIR}/git"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " \
    file://nvidia-sw-einj.service \
    "

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "nvidia-sw-einj.service"

FILES:${PN}:append = " ${systemd_system_unitdir}"
FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-sw-einj.service"
FILES:${PN}:append = " ${datadir}/sw-einj/HMC_SW_EInj_Injector.tar.xz"

FILESEXTRAPATHS:prepend := "${S}:"

# generate_injector_tar_file.sh will crete the tar package under ${S}/deploy
FILESEXTRAPATHS:prepend := "${S}/deploy:"

do_install:append() {
    install -d ${D}${datadir}/sw-einj
    ${S}/generate_injector_tar_file.sh --no-build-tools --no-ssh-deploy
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/nvidia-sw-einj.service ${D}${systemd_system_unitdir}/
    TAR_FILE=$(ls ${S}/deploy/*)
    install -m 0644 ${TAR_FILE} ${D}${datadir}/sw-einj
}
