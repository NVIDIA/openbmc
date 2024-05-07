FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "5d79e84f6e646760b33c976eb8992f6855b44b98"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "
