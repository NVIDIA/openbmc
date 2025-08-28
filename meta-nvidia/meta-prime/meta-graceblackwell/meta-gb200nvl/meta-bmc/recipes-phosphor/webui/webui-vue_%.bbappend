FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           "
SRCREV = "99702c33a18120902ba369862ca1fa5f7e3265ab"

EXTRA_OENPM = "-- --mode nvidia-gb"
