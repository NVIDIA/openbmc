FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# AXBUGS-1872
SRC_URI:append:gb200nvl-bmc-axiado = " file://0001-Enabling-virtual-media-according-to-nvidia-UDC.patch"
SRC_URI:append:gb300nvl-bmc-axiado = " file://0001-Enabling-virtual-media-according-to-nvidia-UDC.patch"
SRC_URI:append:gb200nvl-bmc-axiado-github = " file://0001-Enabling-virtual-media-according-to-nvidia-UDC-github.patch"

