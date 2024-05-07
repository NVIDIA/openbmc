#
# Use updated SRCREV from NVIDIA repo for Grace platforms
# This gives us the option to log raw SSIF bytes
#

SRC_URI = "git://github.com/NVIDIA/ssifbridge;protocol=https;branch=develop;name=override; \
           file://0001-Start-SSIF-bridge-in-verbose-mode.patch \
           "
SRCREV= "d418250030d52a416bf15da529848365cbe2d299"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

