SUMMARY = "CPER File parser"
DESCRIPTION = "CPER File parser"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

inherit pkgconfig meson

DEPENDS += "cli11"
DEPENDS += "nlohmann-json"

SRC_URI = "git://github.com/NVIDIA/cper-decoder;protocol=https;branch=develop"
SRCREV = "057f914ab0ff7ff6bb74057d0ba9081327e42e21"

S = "${WORKDIR}/git"

#TO DO
do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/build/cperparse ${D}/${bindir}/cperparse
}
