FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/libpldm;protocol=https;branch=develop"
SRCREV = "3b17a14d205d21c1e39d7603d3340020989802a2"

EXTRA_OEMESON += " \
    -Doem-nvidia=enabled \
    "
