FILESEXTRAPATHS:append := "${THISDIR}/phosphor-post-code-manager:"

SRC_URI:append = " \
           file://post-code.fs_dep.conf \
           file://check_logmount.sh \
           "
RDEPENDS:${PN}-manager += "bash"
RDEPENDS:${PN} += "bash"

FILES:${PN}-manager +=  "${bindir}/check_logmount.sh"

FILES:${PN}-manager:append = " ${systemd_system_unitdir}/xyz.openbmc_project.State.Boot.PostCode@.service.d/post-code.fs_dep.conf"
SYSTEMD_OVERRIDE:${PN}-manager += "post-code.fs_dep.conf:xyz.openbmc_project.State.Boot.PostCode@.service.d/post-code.fs_dep.conf"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}/xyz.openbmc_project.State.Boot.PostCode@.service.d
    install -m 755 ${WORKDIR}/check_logmount.sh ${D}${bindir}/
    install -m 0644 ${WORKDIR}/post-code.fs_dep.conf ${D}${systemd_system_unitdir}/xyz.openbmc_project.State.Boot.PostCode@.service.d/
}

FILES:${PN} += " ${systemd_system_unitdir}/xyz.openbmc_project.State.Boot.PostCode@.service.d"
