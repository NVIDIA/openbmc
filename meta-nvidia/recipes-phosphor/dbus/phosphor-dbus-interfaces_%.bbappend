FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "cacd6de9e92687bddd1c34597ad73bb2cef51671"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "
