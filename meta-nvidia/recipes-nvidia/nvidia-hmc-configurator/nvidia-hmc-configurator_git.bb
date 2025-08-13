SUMMARY = "Nvidia HMC Configurator"
DESCRIPTION = "A collection of apps to interact with the HMC through Redfish"

SRC_URI = "git://github.com/NVIDIA/nvidia-hmc-configurator;protocol=https;branch=develop"
SRCREV = "3f73035c0c217c8a0ffbfc31c4ae40a1577c3136"

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
