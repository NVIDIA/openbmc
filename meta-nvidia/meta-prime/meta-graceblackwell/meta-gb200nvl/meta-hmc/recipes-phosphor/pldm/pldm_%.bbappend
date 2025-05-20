RDEPENDS:${PN} += " bash"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
inherit systemd

EXTRA_OEMESON:append = " -Dnvlink-c2c-fabric-object=disabled "
EXTRA_OEMESON += "${@bb.utils.contains('DISTRO_FEATURES', 'mctp-inkernel', ' -Denable-in-kernel-mctp=enabled', '', d)}"

SRC_URI:append = " file://fw_update_config_c1g1.json \
                   file://fw_update_config_c1g2.json \
                   file://pldm_cfg_setup.sh \
                   file://pldm_cfg_setup.service"

EXTRA_OEMESON += "-Dlibpldmresponder=enabled"
EXTRA_OEMESON:append = " -Dplatform-chassis-object-path='/xyz/openbmc_project/inventory/system/chassis/HGX_Chassis_0'"

SYSTEMD_SERVICE:${PN}:append = " pldm_cfg_setup.service"

do_install:append() {
    rm -f ${D}${datadir}/pldm/fw_update_config.json

    install -d ${D}${datadir}/pldm/platform-config-files
    install -d ${D}/etc/pldm
    install -m 0644 ${WORKDIR}/fw_update_config_c1g2.json ${D}/etc/pldm/fw_update_config.json
    ln -sf /etc/pldm/fw_update_config.json ${D}${datadir}/pldm/fw_update_config.json
    install -m 0644 ${WORKDIR}/fw_update_config_c1g2.json ${D}${datadir}/pldm/platform-config-files
    install -m 0644 ${WORKDIR}/fw_update_config_c1g1.json ${D}${datadir}/pldm/platform-config-files
    install -m 0755 ${WORKDIR}/pldm_cfg_setup.sh ${D}/${bindir}/pldm_cfg_setup.sh
    install -m 0644 ${WORKDIR}/pldm_cfg_setup.service ${D}${base_libdir}/systemd/system
    rm -rf ${D}/${systemd_system_unitdir}/pldmd.service.d
}

