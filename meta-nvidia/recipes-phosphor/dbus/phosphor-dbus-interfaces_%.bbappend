FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "61be64e99ba23b83e1068b61bad8fa5828d3adf1"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "

EXTRA_OEMESON += "-Dcpp_std=c++23"
