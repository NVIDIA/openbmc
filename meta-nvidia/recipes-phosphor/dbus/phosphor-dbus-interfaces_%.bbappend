FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "a51c3e0c650708a152706d27c151d5c499f10467"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "

EXTRA_OEMESON += "-Dcpp_std=c++23"
