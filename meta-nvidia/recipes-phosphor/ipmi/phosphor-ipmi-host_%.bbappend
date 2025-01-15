FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " git://github.com/NVIDIA/phosphor-host-ipmid;protocol=https;branch=develop;name=override;"
SRCREV_FORMAT = "override"

SRCREV_override = "0853b960bf17161b2ff230220ed0b589ba85544e"

FILES:${PN}:append = " /usr/local/include/phosphor-ipmi-host/sensorhandler.hpp"
FILES:${PN}:append = " /usr/local/include/phosphor-ipmi-host/selutility.hpp"

SRC_URI += "file://host-ipmid-whitelist_nvidia.conf"

WHITELIST_CONF:append = " ${WORKDIR}/host-ipmid-whitelist_nvidia.conf"
EXTRA_OECONF:append = " --enable-dbus-logger=yes"

do_install:append(){
  install -d ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/commonselutility.hpp ${D}${includedir}/phosphor-ipmi-host
}
