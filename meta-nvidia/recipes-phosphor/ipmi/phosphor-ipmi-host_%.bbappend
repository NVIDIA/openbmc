FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " git://github.com/NVIDIA/phosphor-host-ipmid;protocol=https;branch=develop;name=override;"
SRCREV_FORMAT = "override"

SRCREV_override = "584a41597494f5e6201529979e242e523840c269"

FILES:${PN}:append = " /usr/local/include/phosphor-ipmi-host/sensorhandler.hpp"
FILES:${PN}:append = " /usr/local/include/phosphor-ipmi-host/selutility.hpp"

SRC_URI += "file://host-ipmid-whitelist_nvidia.conf"
SRC_URI += "file://pam.d/host-ipmid"

WHITELIST_CONF:append = " ${UNPACKDIR}/host-ipmid-whitelist_nvidia.conf"
EXTRA_OECONF:append = " --enable-dbus-logger=yes"
#EXTRA_OEMESON:append = " -Dpam-service-name=host-ipmid"

do_install:append(){
  install -d ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/commonselutility.hpp ${D}${includedir}/phosphor-ipmi-host

  for CONF in ${EXTRA_OEMESON}; do
    if echo ${CONF} | grep -q "pam-service-name"; then
      PAMSERVICE=$(echo ${CONF} | cut -d "=" -f 2)
    fi
  done
  if [ ! -z "${PAMSERVICE}" ] && [ -f ${WORKDIR}/pam.d/${PAMSERVICE} ]; then
    install -d ${D}${sysconfdir}/pam.d
    install -m 0644 ${WORKDIR}/pam.d/${PAMSERVICE} ${D}${sysconfdir}/pam.d/
  fi
}
