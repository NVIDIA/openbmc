#
# Use updated SRCREV from NVIDIA repo for Grace platforms
# This gives us the option to log raw SSIF bytes
#

SRC_URI = "git://github.com/NVIDIA/ssifbridge;protocol=https;branch=develop;name=override; \
           "
SRCREV= "c79646811be5ab47953fe0c5ae92bffc9c661e70"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

