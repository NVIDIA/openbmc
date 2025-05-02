
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI = "git://github.com/NVIDIA/phosphor-health-monitor;protocol=https;branch=develop"
SRCREV = "1960cf4c2ab4863127e109c16a03ea1d8959599a"

SRC_URI:append = " file://bmc_health_config.json"
SRC_URI:append = " file://process_health_config.json"
RDEPENDS:${PN} += "bash"

SYSTEMD_SERVICE:${PN} = "phosphor-health-monitor.service phosphor-ipc-monitor.service HMSystemRecovery@.service HMSystemWarning@.service HMServiceWarning@.service HMServiceRecovery@.service HMIpcRestart@.service"

do_install:append() {
  # Check if process_health_config.json exists and install it
  if [ -e "${WORKDIR}/process_health_config.json" ]; then
    install -d ${D}${sysconfdir}/healthMon
    install -m 0644 ${WORKDIR}/process_health_config.json ${D}${sysconfdir}/healthMon
  fi
}
