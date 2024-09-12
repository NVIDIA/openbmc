FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "8a27d552d4a761f285402bf4ac1b327dc314f23a"

EXTRA_OENPM = "-- --mode nvidia-gb"
