FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "653be6309ec0fed31bfdbd971fe56f911d2d769a"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "
