FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "080763ccf80db3f2d5562700a165cfd22ab1a597"

EXTRA_OENPM = "-- --mode nvidia-gb"
