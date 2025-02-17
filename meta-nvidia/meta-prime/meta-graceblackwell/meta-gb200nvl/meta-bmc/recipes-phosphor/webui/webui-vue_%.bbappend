FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "bf199c5c73511bb4e3400581eea8b5f34ae4a188"

EXTRA_OENPM = "-- --mode nvidia-gb"
