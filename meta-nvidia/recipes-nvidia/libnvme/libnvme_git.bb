SUMMARY = "NVMe-MI Library"
DESCRIPTION = "NVMe-MI Library"

SRC_URI = "git://github.com/NVIDIA/libnvme;protocol=https;branch=develop"
SRCREV= "c987fc13ebff727990ef4921f655a3e5f0b51f82"


LICENSE = "LGPL-2.1"
LIC_FILES_CHKSUM = "file://COPYING;md5=4fbd65380cdd255951079008b364516c"

inherit pkgconfig meson systemd

DEPENDS += "dbus"
S = "${WORKDIR}/git"

