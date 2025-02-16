SUMMARY = "Nvidia HMC Configurator"
DESCRIPTION = "A collection of apps to interact with the HMC through Redfish"

SRC_URI = "git://github.com/NVIDIA/nvidia-hmc-configurator;protocol=https;branch=develop"
SRCREV = "529075d5912a7eb204e0e6f220552b7f257662a3"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = "file://LICENSE;md5=12353aeba23f8160230377e87875be6c"

DEPENDS = " \
    boost \
    nlohmann-json \
    sdbusplus \
    nghttp2 \
    libpwquality \
    gtest \
    "

inherit pkgconfig meson systemd

S = "${WORKDIR}/git"
