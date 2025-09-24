DESCRIPTION = "blhost Application"
LICENSE = "BSD-3-Clause & MIT & CC0-1.0"

LIC_FILES_CHKSUM = " \
    file://license-public.txt;md5=1b92351acfe5764a233803489b520614 \
    file://src/blfwk/json.h;md5=103fb1035d39134ae18e437f3538d00a \
"
SRC_URI = "git://github.com/NVIDIA/blhost;protocol=https;branch=main"
SRCREV = "2efbd718f1970c211c7da9a9236edfafa51b983a"

inherit meson
S = "${WORKDIR}/git"
#B = "${WORKDIR}/build"
#BOOT_ROOT = "${S}"

DEPENDS += "libusb1"
DEPENDS += "glibc gcc-runtime"

FILES_${PN} = "${bindir}/blhost"
