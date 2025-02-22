SUMMARY = "Remote Media Service"
DESCRIPTION = "Remote Media Service"

DEPENDS = "udev boost nlohmann-json systemd sdbusplus "
DEPENDS += "phosphor-logging"
RDEPENDS:${PN} += " nbdkit"

SRC_URI = "git://github.com/NVIDIA/remote-media;protocol=https;branch=develop"
SRCREV = "5827e7f54877b8bb785079ccf1b50b5d5ed0f705"

S = "${WORKDIR}/git"
PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.VirtualMedia.service"

inherit cmake systemd pkgconfig

FULL_OPTIMIZATION = "-Os -pipe -flto"
EXTRA_OECMAKE += "-DYOCTO_DEPENDENCIES=ON"
