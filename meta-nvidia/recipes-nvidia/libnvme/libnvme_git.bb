SUMMARY = "NVMe-MI Library"
DESCRIPTION = "NVMe-MI Library"

SRC_URI = "git://github.com/NVIDIA/libnvme;protocol=https;branch=develop"
SRCREV= "fadce47398ee5c6bbb7c1c0d0ad1d49c93be0f61"


LICENSE = "LGPL-2.1-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=4fbd65380cdd255951079008b364516c"

inherit pkgconfig meson systemd

DEPENDS += "dbus libmctp"
S = "${WORKDIR}/git"

