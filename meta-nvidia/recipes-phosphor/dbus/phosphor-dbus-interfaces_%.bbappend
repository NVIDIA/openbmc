FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "da7eaec86a57ae6b4172a094a1b5132f8be05bef"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "

EXTRA_OEMESON += "-Dcpp_std=c++23"
