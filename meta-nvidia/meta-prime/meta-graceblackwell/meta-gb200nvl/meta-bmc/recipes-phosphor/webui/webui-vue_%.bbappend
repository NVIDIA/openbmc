FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "67bab50225e50b39b1ebaa19795ff7288d179cdc"

EXTRA_OENPM = "-- --mode nvidia-gb"
