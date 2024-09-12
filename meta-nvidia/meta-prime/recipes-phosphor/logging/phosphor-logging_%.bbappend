FILESEXTRAPATHS:append := "${THISDIR}/config:"

SRC_URI:append = " \
           file://log.fs_dep.conf \
           file://check_logmount.sh \
           "

FILES:${PN}-manager +=  "${bindir}/check_logmount.sh"

RDEPENDS:${PN}-manager += "bash"
RDEPENDS:${PN} += "bash"

FILES:${PN}-manager:append = " ${systemd_system_unitdir}/xyz.openbmc_project.Logging.service.d/log.fs_dep.conf"
SYSTEMD_OVERRIDE:${PN}-manager += "log.fs_dep.conf:xyz.openbmc_project.Logging.service.d/log.fs_dep.conf"

do_install:append() {
        install -m 755 ${WORKDIR}/check_logmount.sh ${D}${bindir}/
}

do_install:append() {
    install -d ${D}${systemd_system_unitdir}/xyz.openbmc_project.Logging.service.d
    install -m 0644 ${WORKDIR}/log.fs_dep.conf ${D}${systemd_system_unitdir}/xyz.openbmc_project.Logging.service.d/
}

FILES:${PN} += " ${systemd_system_unitdir}/xyz.openbmc_project.Logging.service.d"

