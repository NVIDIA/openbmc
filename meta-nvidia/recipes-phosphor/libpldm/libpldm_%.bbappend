FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/libpldm;protocol=https;branch=develop"
SRCREV = "554f6c5b8bbabea869c8c65c274cb607f295748d"

EXTRA_OEMESON += " \
    -Doem=nvidia\
    "
