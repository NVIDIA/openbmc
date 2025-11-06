FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/libpldm;protocol=https;branch=develop"
SRCREV = "6b46d3b1a65e64f870cee07dd30de5ae30c2a3bd"

EXTRA_OEMESON += " \
    -Doem=nvidia\
    "
