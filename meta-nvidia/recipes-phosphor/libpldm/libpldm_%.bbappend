FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/libpldm;protocol=https;branch=develop"
SRCREV = "984c46f00d87a800f053a461c8b81766917a4d91"

EXTRA_OEMESON += " \
    -Doem-nvidia=enabled \
    "
