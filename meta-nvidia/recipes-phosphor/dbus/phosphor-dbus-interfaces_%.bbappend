FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "537b6a0f6e86b49d8b1a2a6a9dd75373592e44d0"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "
