SUMMARY = "Rack Power Controller"
DESCRIPTION = "Rack Power Controller"
 
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=424b4b48c3ba5f01f3b673daccb8ccd5"

SRC_URI = "git://github.com/NVIDIA/RackPowerController;protocol=https;branch=main"
SRCREV = "110e74c29c2e73c3955c23597f05af10152857b8"

inherit pkgconfig meson

DEPENDS = " \
    redis-plus-plus \
    yaml-cpp \
    nlohmann-json \
"

S = "${WORKDIR}/git"

