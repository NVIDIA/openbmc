FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG[processorstatus] = "-Dprocstatus=enabled, -Dprocstatus=disabled"
PACKAGECONFIG[nvmestatus] = "-Dnvmeu2=enabled, -Dnvmeu2=disabled"
PACKAGECONFIG[plx-temp] = "-Dplx-temp=enabled, -Dplx-temp=disabled"
PACKAGECONFIG[ipmbstatus] = "-Dipmbstatus=enabled, -Dipmbstatus=disabled"
PACKAGECONFIG[satellitesensor] = "-Dsatellite=enabled, -Dsatellite=disabled"

PACKAGECONFIG:append = " nvmesensor \
                         processorstatus \
                         satellitesensor \
                         nvmestatus "

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'nvmesensor', \
                                               'xyz.openbmc_project.nvmesensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'processorstatus', \
                                               'xyz.openbmc_project.processorstatus.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'nvmestatus', \
                                               'xyz.openbmc_project.nvmestatus.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'plx-temp', \
                                               'xyz.openbmc_project.plxtempsensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'ipmbstatus', \
                                               'xyz.openbmc_project.ipmbstatus.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'satellitesensor', \
                                               'xyz.openbmc_project.satellitesensor.service', \
                                               '', d)}"

DEPENDS:append = " nvidia-tal"
