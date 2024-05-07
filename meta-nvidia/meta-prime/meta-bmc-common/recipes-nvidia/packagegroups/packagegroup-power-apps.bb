SUMMARY = "OpenBMC for NVIDIA - Applications"
PR = "r1"

inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES = " \
        ${PN}-system \
        "

RPROVIDES:${PN}-system += "nvidia-power-apps"


SUMMARY:${PN}-system = "NVIDIA System"
RDEPENDS:${PN}-system = " \
    obmc-phosphor-buttons \
    obmc-phosphor-buttons-signals \
    obmc-phosphor-buttons-handler \
    "
