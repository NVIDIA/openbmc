# Use NVIDIA gitlab Phosphor Networkd

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-networkd;protocol=https;branch=develop"
SRCREV = "29012198b5c5b6bf07517832c4c763fa105e1ded"

EXTRA_OECONF:append = " --enable-ipv6-accept-ra=yes"

SYSTEMD_SERVICE:${PN} += " bmc-network-online.target"

DEPENDS += "libmctp"
