#
# TODO Copyright info.
#
SUMMARY = "NVIDIA Code management"
DESCRIPTION = "NVIDIA Code management"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=26466f864df20e300683aa7a8d293486"

inherit meson pkgconfig obmc-phosphor-systemd
S = "${WORKDIR}/git"

SRC_URI = "git://github.com/NVIDIA/nvidia-code-mgmt;protocol=https;branch=develop"
SRCREV = "d017eaab51d4a4ee06f1f9a9bfa310bd81ce4ce9"

PV = "0.1+git${SRCPV}"

DEPENDS = " \
         phosphor-logging \
         phosphor-dbus-interfaces \
         sdbusplus \
         sdeventplus \
         openssl \
         nlohmann-json \
         cli11 \
         fmt \
         "
DEPENDS += "${PYTHON_PN}-sdbus++-native"
EXTRA_OEMESON += "-DMOCK_UTILS=false"
SYSTEMD_SERVICE:${PN} = ""

#EXTRA_OEMESON +=-D<VARIABLE>='<Manufacture>:<Model>:<UUID>'"

FILES_${PN}:append = " ${libdir}/*"
