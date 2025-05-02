FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "5b095839fce0d84fbeda1536d6b5c13cdd94990e"

EXTRA_OENPM = "-- --mode nvidia-gb"
