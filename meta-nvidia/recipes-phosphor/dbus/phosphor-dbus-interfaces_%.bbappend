FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "2a7d41f7a0f7e6e31e851cd65370f28950f7a36a"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "

EXTRA_OEMESON += "-Dcpp_std=c++23"
