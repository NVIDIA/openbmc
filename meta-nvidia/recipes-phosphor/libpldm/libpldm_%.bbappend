FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/libpldm;protocol=https;branch=develop"
SRCREV = "5609534129e5ff82e5f22907e60fedf7fca8a839"

EXTRA_OEMESON += " \
    -Doem-nvidia=enabled \
    "
