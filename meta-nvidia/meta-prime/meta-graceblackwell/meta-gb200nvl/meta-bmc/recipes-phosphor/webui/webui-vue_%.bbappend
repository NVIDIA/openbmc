FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "ca1981634208994f15d9324c9447d228f9a98fe4"

EXTRA_OENPM = "-- --mode nvidia-gb"
