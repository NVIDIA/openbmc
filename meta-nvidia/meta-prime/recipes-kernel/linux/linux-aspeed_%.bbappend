# Override some values in linux-aspeed.inc and linux-aspeed_git.bb
# with specifics of our Git repo, branch names, and Linux version
#
LINUX_VERSION = "6.1.15"
SRCREV = "d43b188b0da166309859c56ee13a4b745bed18a8"
KSRC = "git://github.com/NVIDIA/linux;protocol=https;branch=develop-6.1.15"

LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://enable-cifs-protocol.cfg"

