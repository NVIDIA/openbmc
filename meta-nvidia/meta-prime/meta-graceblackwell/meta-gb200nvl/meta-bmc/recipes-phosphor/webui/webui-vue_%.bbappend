FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "d617820167a7f8da2102b23b55206b539b5edeb3"

EXTRA_OENPM = "-- --mode nvidia-gb"
