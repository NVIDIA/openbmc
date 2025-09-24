#
# TODO Copyright info.
#
SUMMARY = "NVIDIA Code management"
DESCRIPTION = "NVIDIA Code management"
RDEPENDS:${PN} += "bash"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=26466f864df20e300683aa7a8d293486"

inherit meson pkgconfig obmc-phosphor-systemd
S = "${WORKDIR}/git"

SRC_URI = "git://github.com/NVIDIA/nvidia-code-mgmt;protocol=https;branch=develop"
SRCREV = "0a699f282aeccc5e0f23cf3bbac64d536184df7f"

PV = "0.1+git${SRCPV}"

DEPENDS = " \
         phosphor-logging \
         phosphor-dbus-interfaces \
         sdbusplus \
         sdeventplus \
         openssl \
         nlohmann-json \
         cli11 \
         libmctp \
         fmt \
         libgpiod \
         libusb1 \
         "
DEPENDS += "${PYTHON_PN}-sdbus++-native"
EXTRA_OEMESON += "-DMOCK_UTILS=false"
SYSTEMD_SERVICE:${PN} = ""

#EXTRA_OEMESON +=-D<VARIABLE>='<Manufacture>:<Model>:<UUID>'"

FILES_${PN}:append = " ${libdir}/*"
