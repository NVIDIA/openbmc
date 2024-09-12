
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI = "git://github.com/NVIDIA/phosphor-health-monitor;protocol=https;branch=develop"
SRCREV = "05be24322d66f3643d8e0ed0cddad500fc750e21"

SRC_URI:append = " file://bmc_health_config.json"
RDEPENDS:${PN} += "bash"

SYSTEMD_SERVICE:${PN} = "phosphor-health-monitor.service phosphor-ipc-monitor.service HMSystemRecovery@.service HMSystemWarning@.service HMServiceWarning@.service HMServiceRecovery@.service HMIpcRestart@.service"

