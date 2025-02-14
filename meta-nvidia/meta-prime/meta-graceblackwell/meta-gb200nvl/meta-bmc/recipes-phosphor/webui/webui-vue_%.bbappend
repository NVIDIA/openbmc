FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "1b3ba37bcb59d97f18203b598478e96dc2bf9adc"

EXTRA_OENPM = "-- --mode nvidia-gb"
