#
# Use updated SRCREV from NVIDIA repo for Grace platforms
# This gives us the option to log raw SSIF bytes
#

SRC_URI = "git://github.com/NVIDIA/ssifbridge;protocol=https;branch=develop;name=override; \
           file://0001-Start-SSIF-bridge-in-verbose-mode.patch \
           "
SRCREV= "792843c54008c0d3196407dc14ec251bb40bc9c3"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

