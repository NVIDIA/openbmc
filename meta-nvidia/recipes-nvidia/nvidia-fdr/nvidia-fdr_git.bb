SUMMARY = "NVIDIA Flight Data Recorder Module"
DESCRIPTION = "NVIDIA Flight Data Recorder Module"
HOMEPAGE = "https://gitlab-master.nvidia.com/dgx/nvidia-fdr"
PR = "r1"
PV = "0.1+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

# Use below if local development repo is prefered, please commit the change first.
#SRC_URI = "git:///path/to/nvidia-fdr;protocol=file;;branch=<branch name>"
SRC_URI = "git://github.com/NVIDIA/nvidia-fdr;protocol=https;branch=develop"

# Modify these as desired
#PV = "1.0+git${SRCPV}"
SRCREV = "a037ead74575c2e69a536e2adb7f4a39b0ef4d3d"

S = "${WORKDIR}/git"

inherit pkgconfig
inherit meson
inherit systemd

EXTRA_OEMESON = "-Dtests=disabled"

DEPENDS = " \
    curl \
    fmt \
    nlohmann-json \
    phosphor-logging \
    protobuf \
    protobuf-native \
    python3-pyyaml-native\
    sdbusplus \
    sdeventplus \
    spdlog \
    systemd \
    yaml-cpp \
"
DEPENDS += "nvidia-shmem"

RDEPENDS:${PN} += "bash"


FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "nvidia-fdr.service"

SRC_URI += " \
           file://nvidia-fdr.service \
           file://fdr_platforms.sh \
           "



FILES:${PN}:append = " ${bindir}/fdr"
FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-fdr.service"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/nvidia-*.service ${D}${systemd_system_unitdir}
    install -m 0755 ${WORKDIR}/fdr_platforms.sh ${D}/${bindir}/
}
