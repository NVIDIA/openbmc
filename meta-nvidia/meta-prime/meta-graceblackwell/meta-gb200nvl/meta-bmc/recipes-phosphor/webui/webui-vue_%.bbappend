FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "d67e6eaf7f47bb3c47e663bda8b299c12ea8d0df"

EXTRA_OENPM = "-- --mode nvidia-gb"
