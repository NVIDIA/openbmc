#
# TODO Copyright info.
#
SUMMARY = "NVIDIA Code management"
DESCRIPTION = "NVIDIA Code management"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=26466f864df20e300683aa7a8d293486"

inherit meson pkgconfig obmc-phosphor-systemd
S = "${WORKDIR}/git"

SRC_URI = "git://github.com/NVIDIA/nvidia-code-mgmt;protocol=https;branch=Core-24.09-1_br"
SRCREV = "805f516840254f3c5be765d6d64e9fa97a077882"

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
         "
DEPENDS += "${PYTHON_PN}-sdbus++-native"
EXTRA_OEMESON += "-DMOCK_UTILS=false"
SYSTEMD_SERVICE:${PN} = ""

#EXTRA_OEMESON +=-D<VARIABLE>='<Manufacture>:<Model>:<UUID>'"

FILES_${PN}:append = " ${libdir}/*"
