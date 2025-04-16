#
# Use updated SRCREV from NVIDIA repo for Grace platforms
# This gives us the option to log raw SSIF bytes
#

SRC_URI = "git://github.com/NVIDIA/ssifbridge;protocol=https;branch=develop;name=override; \
           file://0001-Start-SSIF-bridge-in-verbose-mode.patch \
           "
SRCREV= "cfb8647eee960ec542cd2d05c6e6c31ca019994c"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

