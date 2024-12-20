SUMMARY = "NVIDIA TAL"
DESCRIPTION = "NVIDIA TAL Library and Tools"
PR = "r1"
PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

inherit meson pkgconfig

S = "${WORKDIR}/git"

DEPENDS += "boost"
DEPENDS += "phosphor-logging"
DEPENDS += "nvidia-shmem"

SRC_URI = "git://github.com/NVIDIA/nvidia-tal;protocol=https;branch=develop"
SRCREV = "e183b6d0d61cdea68b1ad9135229d04aac03d8fb"

FILESEXTRAPATHS:prepend := "${THISDIR}:"
SRC_URI += "file://smbus-telemetry-config/smbus-telemetry-config.csv" 

do_install:append() {
    install -d ${D}${datadir}/smbus-telemetry-target
    install -m 0644 ${WORKDIR}/smbus-telemetry-config/smbus-telemetry-config.csv ${D}${datadir}/smbus-telemetry-target/
}

FILES:${PN} += " /usr/share"

EXTRA_OEMESON = "-Dtests=disabled -Dsmbus-telemetry-target=enabled"
