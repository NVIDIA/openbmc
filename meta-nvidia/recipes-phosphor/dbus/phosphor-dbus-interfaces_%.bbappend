FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-dbus-interfaces;protocol=https;branch=develop"
SRCREV = "3f32e9887990dbcede0d369e96a957637c091925"

EXTRA_OEMESON:append = " \
     -Ddata_com_nvidia=true \
     "
