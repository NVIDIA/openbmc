SUMMARY = "CPER File parser"
DESCRIPTION = "CPER File parser"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

inherit meson

DEPENDS += "nlohmann-json"

SRC_URI = "git://github.com/NVIDIA/cper-decoder;protocol=https;branch=develop"
SRCREV = "6b3c2b125c92e3b793c67b0e8177cf906ade2193"

S = "${WORKDIR}/git"

#TO DO
do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/build/cperparse ${D}/${bindir}/cperparse
}
