RDEPENDS:${PN} += " bash"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
inherit systemd

EXTRA_OEMESON:append = " -Dnvlink-c2c-fabric-object=disabled "

SRC_URI:append = " file://fw_update_config.json \
                   file://fw_update_config_c1g1.json \
                   file://pldm_cfg_setup.sh \
                   file://pldm_cfg_setup.service"

EXTRA_OEMESON += "-Dlibpldmresponder=enabled"

SYSTEMD_SERVICE:${PN}:append = " pldm_cfg_setup.service"

do_install:append() {
    rm -f ${D}${datadir}/pldm/fw_update_config.json

    install -d ${D}${datadir}/pldm/platform-config-files
    install -m 0644 ${WORKDIR}/fw_update_config.json ${D}${datadir}/pldm/
    install -m 0644 ${WORKDIR}/fw_update_config.json ${D}${datadir}/pldm/platform-config-files
    install -m 0644 ${WORKDIR}/fw_update_config_c1g1.json ${D}${datadir}/pldm/platform-config-files
    install -m 0755 ${WORKDIR}/pldm_cfg_setup.sh ${D}/${bindir}/pldm_cfg_setup.sh
    install -m 0644 ${WORKDIR}/pldm_cfg_setup.service ${D}${base_libdir}/systemd/system
    rm -rf ${D}/${systemd_system_unitdir}/pldmd.service.d
}

