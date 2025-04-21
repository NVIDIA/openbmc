SUMMARY = "Nvidia NVMe Manager"
DESCRIPTION = "NVMe Services Configured from D-Bus"

SRC_URI = "git://github.com/NVIDIA/nvidia-nvme-manager;protocol=https;branch=Core-24.09-1_br"
SRCREV= "14befb54f8f9b605851d8f183a69b529e5957f66"


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
