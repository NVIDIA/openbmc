SUMMARY = "NVIDIA BMC USB utils"
DESCRIPTION = "USB utils package for NVIDIA BMC/HMC"
LICENSE = "CLOSED"
DEPENDS = "libusb1"
LIC_FILES_CHKSUM = ""

inherit autotools pkgconfig meson
S = "${WORKDIR}/git"

SRC_URI = "git://github.com/NVIDIA/usb-transfer-tool;protocol=https;branch=develop"
SRCREV = "cd5f0a3ca85a17a179119f30216c7623ef85230f"

FILES:${PN} = "${bindir}/usb_transfer_tool"

do_install() {
   install -d ${D}/${bindir}
   install -m 0755 ${B}/usb_transfer_tool ${D}/${bindir}/
}
