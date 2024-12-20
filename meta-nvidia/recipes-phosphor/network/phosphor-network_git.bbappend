# Use NVIDIA gitlab Phosphor Networkd

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-networkd;protocol=https;branch=develop"
SRCREV = "de4b697833052cb439d1a80c7373b42235500c29"

EXTRA_OECONF:append = " --enable-ipv6-accept-ra=yes"

SYSTEMD_SERVICE:${PN} += " bmc-network-online.target"

DEPENDS += "libmctp"
