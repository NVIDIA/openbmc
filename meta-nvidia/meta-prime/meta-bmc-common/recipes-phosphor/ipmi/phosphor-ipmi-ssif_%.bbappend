#
# Use updated SRCREV from NVIDIA repo for Grace platforms
# This gives us the option to log raw SSIF bytes
#

SRC_URI = "git://github.com/NVIDIA/ssifbridge;protocol=https;branch=develop;name=override; \
           file://0001-Start-SSIF-bridge-in-verbose-mode.patch \
           "
SRCREV= "59b51fc0aa5d1ed87c36c5912d129468ca989147"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

