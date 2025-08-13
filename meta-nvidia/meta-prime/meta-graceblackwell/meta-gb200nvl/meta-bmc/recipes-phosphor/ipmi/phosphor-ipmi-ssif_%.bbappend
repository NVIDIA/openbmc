#
# Use updated SRCREV from NVIDIA repo for Grace platforms
# This gives us the option to log raw SSIF bytes
#

SRC_URI = "git://github.com/NVIDIA/ssifbridge;protocol=https;branch=develop;name=override; \
           "
SRCREV= "88ae427d56d17e9499b790698cb6195760457cf4"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

