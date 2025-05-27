FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "d21397cfe7c4efe3909e7b2ccae1f44fa58df563"

EXTRA_OENPM = "-- --mode nvidia-gb"
