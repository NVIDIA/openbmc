# Use NVIDIA gitlab Phosphor Networkd

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-networkd;protocol=https;branch=develop"
SRCREV = "5396ea8904c67a01d4e47a8026ac63be755f9cfa"

EXTRA_OECONF:append = " --enable-ipv6-accept-ra=yes"

SYSTEMD_SERVICE:${PN} += " bmc-network-online.target"

DEPENDS += "libmctp"
