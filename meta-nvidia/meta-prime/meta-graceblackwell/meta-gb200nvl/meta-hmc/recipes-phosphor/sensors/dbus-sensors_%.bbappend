PACKAGECONFIG[processorstatus] = "-Dprocstatus=disabled, -Dprocstatus=disabled"
PACKAGECONFIG[nvmestatus] = "-Dnvmeu2=disabled, -Dnvmeu2=disabled"
PACKAGECONFIG[plx-temp] = "-Dplx-temp=disabled, -Dplx-temp=disabled"
PACKAGECONFIG[ipmbstatus] = "-Dipmbstatus=enabled, -Dipmbstatus=disabled"
PACKAGECONFIG[presence-detect] = "-Dpresence-detect=enabled, -Dpresence-detect=disabled"
PACKAGECONFIG = " hwmontempsensor \
                  presence-detect "

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'presence-detect', \
                                               'xyz.openbmc_project.presence-detect.service', \
                                               '', d)}"

do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/systemd/system/xyz.openbmc_project.satellitesensor.service
}
