SUMMARY = "NVMe-MI Library"
DESCRIPTION = "NVMe-MI Library"

SRC_URI = "git://github.com/NVIDIA/libnvme;protocol=https;branch=develop"
SRCREV= "b9ea1afb71d54e776eef51a7cf519af94459bd0b"


LICENSE = "LGPL-2.1"
LIC_FILES_CHKSUM = "file://COPYING;md5=4fbd65380cdd255951079008b364516c"

inherit pkgconfig meson systemd

DEPENDS += "dbus libmctp"
S = "${WORKDIR}/git"

