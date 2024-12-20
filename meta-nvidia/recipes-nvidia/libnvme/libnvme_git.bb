SUMMARY = "NVMe-MI Library"
DESCRIPTION = "NVMe-MI Library"

SRC_URI = "git://github.com/NVIDIA/libnvme;protocol=https;branch=develop"
SRCREV= "89f0a88f8588a763ee0e4bf5201de33f72eb3413"


LICENSE = "LGPL-2.1"
LIC_FILES_CHKSUM = "file://COPYING;md5=4fbd65380cdd255951079008b364516c"

inherit pkgconfig meson systemd

DEPENDS += "dbus libmctp"
S = "${WORKDIR}/git"

