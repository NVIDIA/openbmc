# Override some values in linux-aspeed.inc and linux-aspeed_git.bb
# with specifics of our Git repo, branch names, and Linux version
#
LINUX_VERSION = "6.1.15"
SRCREV = "554c20eaaa81f49fb8e3d57e62d8817bd2b0f5f8"
KSRC = "git://github.com/NVIDIA/linux;protocol=https;nobranch=1"

LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://enable-cifs-protocol.cfg"
