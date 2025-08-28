# Use NVIDIA gitlab Phosphor Networkd

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-networkd;protocol=https;branch=develop"
SRCREV = "60668d6224c8ec2a464408c90a5367059db2abd5"

EXTRA_OECONF:append = " --enable-ipv6-accept-ra=yes"

SYSTEMD_SERVICE:${PN} += " bmc-network-online.target"

DEPENDS += "libmctp"
