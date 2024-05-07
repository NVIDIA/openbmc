FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/libpldm;protocol=https;branch=develop"
SRCREV = "e37f8fc5129e7d8b4f80927d184f6229d404c954"

EXTRA_OEMESON += " \
    -Doem-nvidia=enabled \
    "
