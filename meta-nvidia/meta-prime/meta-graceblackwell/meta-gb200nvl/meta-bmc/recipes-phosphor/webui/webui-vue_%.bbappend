FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "b1b46572bb6e77a22f81bc738fd17b7556314de4"

EXTRA_OENPM = "-- --mode nvidia-gb"
