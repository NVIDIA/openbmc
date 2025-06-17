SUMMARY = "Nvidia NVMe Manager"
DESCRIPTION = "NVMe Services Configured from D-Bus"

SRC_URI = "git://github.com/NVIDIA/nvidia-nvme-manager;protocol=https;branch=develop"
SRCREV= "95b3d6c20a94e4e0b1a0147e102df5a95c2b6cb1"


LICENSE = "CLOSED"
LIC_FILES_CHKSUM = "file://LICENSE;md5=12353aeba23f8160230377e87875be6c"

DEPENDS = " \
    boost \
    nlohmann-json \
    phosphor-logging \
    sdbusplus \
    libnvme\
    "
inherit pkgconfig meson systemd

S = "${WORKDIR}/git"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} += " \
        nvidia-nvme-manager.service \
        "
