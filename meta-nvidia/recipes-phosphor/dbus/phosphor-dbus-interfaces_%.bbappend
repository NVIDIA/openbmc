FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "e9da97ef5bae1b7b785f6acde7fb0bc20e174716"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "
