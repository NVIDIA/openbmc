FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "871b72c0ab2d04872f06e207fb5249c375cb2464"

EXTRA_OENPM = "-- --mode nvidia-gb"
