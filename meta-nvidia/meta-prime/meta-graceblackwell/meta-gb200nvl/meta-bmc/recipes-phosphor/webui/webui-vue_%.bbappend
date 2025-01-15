FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "6d48cbafb023fa2e1b18bd19150e9d765259a14c"

EXTRA_OENPM = "-- --mode nvidia-gb"
