FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "a0b6c7b497819ee38d67f1af4b2cb8a3841ed477"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "
