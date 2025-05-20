FILESEXTRAPATHS:append := "${THISDIR}/config:"

SRC_URI:append = " \
           file://log.fs_dep.conf \
           "


RDEPENDS:${PN}-manager += "bash"
RDEPENDS:${PN} += "bash"

FILES:${PN}-manager:append = " ${systemd_system_unitdir}/xyz.openbmc_project.Logging.service.d/log.fs_dep.conf"
SYSTEMD_OVERRIDE:${PN}-manager += "log.fs_dep.conf:xyz.openbmc_project.Logging.service.d/log.fs_dep.conf"


do_install:append() {
    install -d ${D}${systemd_system_unitdir}/xyz.openbmc_project.Logging.service.d
    install -m 0644 ${WORKDIR}/log.fs_dep.conf ${D}${systemd_system_unitdir}/xyz.openbmc_project.Logging.service.d/
}

FILES:${PN} += " ${systemd_system_unitdir}/xyz.openbmc_project.Logging.service.d"

