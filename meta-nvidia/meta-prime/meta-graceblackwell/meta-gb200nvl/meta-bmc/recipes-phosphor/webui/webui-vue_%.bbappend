FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "3f076b77b395880157a064fbd3bd64f74a55626c"

EXTRA_OENPM = "-- --mode nvidia-gb"
