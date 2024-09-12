# Use NVIDIA gitlab Phosphor Networkd

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-networkd;protocol=https;branch=develop"
SRCREV = "d51bcef512b920e15b512fe8b4a2edde2356f835"

EXTRA_OECONF:append = " --enable-ipv6-accept-ra=yes"

SYSTEMD_SERVICE:${PN} += " bmc-network-online.target"

DEPENDS += "libmctp"
