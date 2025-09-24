FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "ee47699f461907f1f8918d982de0112687c32203"

EXTRA_OENPM = "-- --mode nvidia-gb"
