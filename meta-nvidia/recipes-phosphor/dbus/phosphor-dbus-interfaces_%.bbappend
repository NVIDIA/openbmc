FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "90d54f63509fdf50c1fab1388de9afb98498b055"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "
