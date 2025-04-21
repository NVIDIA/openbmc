FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://xyz.openbmc_project.nvmesensor.conf \
                   file://xyz.openbmc_project.nvmestatus.conf \
                 "

PACKAGECONFIG[processorstatus] = "-Dprocstatus=enabled, -Dprocstatus=disabled"
PACKAGECONFIG[nvmestatus] = "-Dnvmeu2=enabled, -Dnvmeu2=disabled"
PACKAGECONFIG[plx-temp] = "-Dplx-temp=enabled, -Dplx-temp=disabled"
PACKAGECONFIG[ipmbstatus] = "-Dipmbstatus=enabled, -Dipmbstatus=disabled"
PACKAGECONFIG[satellitesensor] = "-Dsatellite=enabled, -Dsatellite=disabled"
PACKAGECONFIG[writeprotectsensor] = "-Dwrite-protect=enabled, -Dwrite-protect=disabled"
PACKAGECONFIG[leakdetectsensor] = "-Dleak-detect=enabled, -Dleak-detect=disabled"
PACKAGECONFIG[synthesizedsensor] = "-Dsynth=enabled, -Dsynth=disabled"

PACKAGECONFIG:append = " nvmesensor \
                         processorstatus \
                         satellitesensor \
                         nvmestatus \
                         leakdetectsensor \
                         writeprotectsensor \
                         synthesizedsensor "

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
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'writeprotectsensor', \
                                               'xyz.openbmc_project.writeprotectsensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'leakdetectsensor', \
                                               'xyz.openbmc_project.leakdetectsensor.service', \
                                               '', d)}"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'synthesizedsensor', \
                                               'xyz.openbmc_project.synthesizedsensor.service', \
                                               '', d)}"                                              

DEPENDS:append = " nvidia-tal"

FILES:${PN}:append =  " \
    /usr/lib/systemd/system/xyz.openbmc_project.nvmesensor.service.d/xyz.openbmc_project.nvmesensor.conf \
    /usr/lib/systemd/system/xyz.openbmc_project.nvmestatus.service.d/xyz.openbmc_project.nvmestatus.conf \
"

do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/systemd/system/xyz.openbmc_project.presence-detect.service

    mkdir -p ${D}${base_libdir}/systemd/system/xyz.openbmc_project.nvmesensor.service.d
    mkdir -p ${D}${base_libdir}/systemd/system/xyz.openbmc_project.nvmestatus.service.d
    
    install -m 0644 ${WORKDIR}/xyz.openbmc_project.nvmesensor.conf \
                    ${D}${systemd_system_unitdir}/xyz.openbmc_project.nvmesensor.service.d/
    install -m 0644 ${WORKDIR}/xyz.openbmc_project.nvmestatus.conf \
                    ${D}${systemd_system_unitdir}/xyz.openbmc_project.nvmestatus.service.d/
}