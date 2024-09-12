FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/libpldm;protocol=https;branch=develop"
SRCREV = "4e381b7b858b30cd1f6135a1e18528368e3bba90"

EXTRA_OEMESON += " \
    -Doem-nvidia=enabled \
    "
