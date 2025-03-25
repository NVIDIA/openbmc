FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG[processorstatus] = "-Dprocstatus=enabled, -Dprocstatus=disabled"
PACKAGECONFIG[nvmestatus] = "-Dnvmeu2=enabled, -Dnvmeu2=disabled"
PACKAGECONFIG[plx-temp] = "-Dplx-temp=enabled, -Dplx-temp=disabled"
PACKAGECONFIG[ipmbstatus] = "-Dipmbstatus=enabled, -Dipmbstatus=disabled"
PACKAGECONFIG[satellitesensor] = "-Dsatellite=enabled, -Dsatellite=disabled"
PACKAGECONFIG[writeprotectsensor] = "-Dwrite-protect=enabled, -Dwrite-protect=disabled"
PACKAGECONFIG[leakdetectsensor] = "-Dleak-detect=enabled, -Dleak-detect=disabled"
PACKAGECONFIG[psusensor] = "-Dpsu=enabled, -Dpsu=disabled"
PACKAGECONFIG[systemsensor] = "-Dsystem=enabled, -Dsystem=disabled"
PACKAGECONFIG[presence-detect] = "-Dpresence-detect=enabled, -Dpresence-detect=disabled"
PACKAGECONFIG[psuredundancystatus] = "-Dpsuredundancy=enabled, -Dpsuredundancy=enabled"
PACKAGECONFIG[externalsensor] = "-Dexternal=enabled, -Dexternal=disabled"
PACKAGECONFIG[fansensor] = "-Dfan=enabled, -Dfan=disabled"
PACKAGECONFIG[synthesizedsensor] = "-Dsynth=enabled, -Dsynth=disabled"

PACKAGECONFIG:append = " nvmesensor \
                         processorstatus \
                         satellitesensor \
                         nvmestatus \
                         writeprotectsensor \
                         leakdetectsensor \
                         psusensor \
                         systemsensor \
                         presencedetectsensor \
                         psuredundancystatus \
                         externalsensor \
                         fansensor \
                         synthesizedsensor "

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'nvmesensor', \
                                               'xyz.openbmc_project.nvmesensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'processorstatus', \
                                               'xyz.openbmc_project.processorstatus.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'satellitesensor', \
                                               'xyz.openbmc_project.satellitesensor.service', \
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
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'writeprotectsensor', \
                                               'xyz.openbmc_project.writeprotectsensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'leakdetectsensor', \
                                               'xyz.openbmc_project.leakdetectsensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'psusensor', \
                                               'xyz.openbmc_project.psusensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'systemsensor', \
                                               'xyz.openbmc_project.systemsensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'presence-detect', \
                                               'xyz.openbmc_project.presence-detect.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'psuredundancystatus', \
                                               'xyz.openbmc_project.psuredundancy.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'external', \
                                               'xyz.openbmc_project.externalsensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'fansensor', \
                                               'xyz.openbmc_project.fansensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'synthesizedsensor', \
                                               'xyz.openbmc_project.synthesizedsensor.service', \
                                               '', d)}"                                              

DEPENDS:append = " nvidia-tal"

do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/systemd/system/xyz.openbmc_project.presence-detect.service
}
