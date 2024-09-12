SUMMARY = "NVIDIA Platform Configuration Manager"
DESCRIPTION = "NVIDIA PCM Bitbake recipe"
HOMEPAGE = "https://gitlab-master.nvidia.com/dgx/bmc/nvidia-pcm"
PR = "r1"
PV = "0.1+git${SRCPV}"

# Need correct license info here before upstream.
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit meson systemd pkgconfig

DEPENDS += "systemd"
DEPENDS += "sdbusplus ${PYTHON_PN}-sdbus++-native"
DEPENDS += "phosphor-logging"
DEPENDS += "nlohmann-json"

SRC_URI += "git://github.com/NVIDIA/nvidia-pcm;protocol=https;branch=develop"
SRCREV = "2eb163d78ab8720ff65232c8b09d66bb1dd429bc"
S = "${WORKDIR}/git"

EXTRA_OEMESON += "-Ddebug_log=1"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

FILES:${PN}:append = " ${bindir}/pcmd"
FILES:${PN}:append = " ${libdir}/libpcm${SOLIBS}"

SRC_URI += " \ 
    file://nvidia-pcm.service \
    file://platform-configuration-files/plat_config_GB200.json \
    file://default_platform_configuration.json \
    "   

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "nvidia-pcm.service"

FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-*.service"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/nvidia-*.service ${D}${systemd_system_unitdir}/

    install -d ${D}${datadir}/nvidia-pcm/platform-configuration-files/
    install -m 0644 ${WORKDIR}/platform-configuration-files/plat_config_GB200.json ${D}${datadir}/nvidia-pcm/platform-configuration-files/
    install -m 0644 ${WORKDIR}/default_platform_configuration.json ${D}${datadir}/nvidia-pcm/
}

