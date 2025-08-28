FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "9f6da92c0a95e1fb60df45a6da06e72646117e0a"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "

EXTRA_OEMESON += "-Dcpp_std=c++23"
