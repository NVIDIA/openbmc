FILESEXTRAPATHS:prepend := "${THISDIR}/files:"


SRC_URI:append = " \
                    file://xyz.openbmc_project.FruDevice.conf \
"

FILES:${PN}:append = " \
    ${systemd_system_unitdir}/xyz.openbmc_project.FruDevice.service.d/xyz.openbmc_project.FruDevice.conf \
"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}/xyz.openbmc_project.FruDevice.service.d
    install -m 0644 ${WORKDIR}/xyz.openbmc_project.FruDevice.conf ${D}${systemd_system_unitdir}/xyz.openbmc_project.FruDevice.service.d/
     sed -i '/^WantedBy=multi-user.target/d' ${D}${systemd_system_unitdir}/xyz.openbmc_project.FruDevice.service
}
