FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "57e9f90e131e92f4316a2a4cd843c6bd4f9d8674"

EXTRA_OENPM = "-- --mode nvidia-gb"
