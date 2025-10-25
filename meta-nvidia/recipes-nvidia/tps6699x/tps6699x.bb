SUMMARY = "TPS6699x TFU host tool"
DESCRIPTION = "Fw update support for TPS6699x"
LICENSE = "CLOSED"

inherit meson externalsrc

SRC_URI += "git://github.com/NVIDIA/tps6699x;protocol=https;branch=main"
SRCREV = "bac2d568d2ea1fecbf5d5fd24be428ef223e533a"
S = "${WORKDIR}/git"
