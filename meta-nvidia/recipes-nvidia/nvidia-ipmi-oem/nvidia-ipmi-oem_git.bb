SUMMARY = "NVIDIA OEM IPMI commands"
DESCRIPTION = "NVIDIA OEM IPMI commands"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"



SRC_URI = "git://github.com/NVIDIA/nvidia-ipmi-oem;protocol=https;branch=develop"
SRCREV = "3f88bd1a7294767330eb02d14f1428e28e04a79a"

S = "${WORKDIR}/git"
PV = "0.1+git${SRCPV}"

DEPENDS = "boost phosphor-ipmi-host phosphor-logging systemd phosphor-dbus-interfaces libgpiod"

inherit cmake obmc-phosphor-ipmiprovider-symlink pkgconfig

EXTRA_OECMAKE="-DENABLE_TEST=0 -DYOCTO=1"

LIBRARY_NAMES = "libznvipmioemcmds.so"

HOSTIPMI_PROVIDER_LIBRARY += "${LIBRARY_NAMES}"
NETIPMI_PROVIDER_LIBRARY += "${LIBRARY_NAMES}"

FILES:${PN}:append = " ${libdir}/ipmid-providers/lib*${SOLIBS}"
FILES:${PN}:append = " ${libdir}/host-ipmid/lib*${SOLIBS}"
FILES:${PN}:append = " ${libdir}/net-ipmid/lib*${SOLIBS}"
FILES:${PN}-dev:append = " ${libdir}/ipmid-providers/lib*${SOLIBSDEV}"

do_install:append(){
   install -d ${D}${includedir}/nvidia-ipmi-oem
   install -m 0644 -D ${S}/include/*.hpp ${D}${includedir}/nvidia-ipmi-oem
}
