FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

EXTRA_OEMESON:append = " -Dnvlink-c2c-fabric-object=disabled "

SRC_URI:append = " file://fw_update_config.json "

EXTRA_OEMESON += "-Dlibpldmresponder=enabled"

do_install:append() {
    rm -f ${D}${datadir}/pldm/fw_update_config.json

    install -m 0644 ${WORKDIR}/fw_update_config.json ${D}${datadir}/pldm/
    rm -rf ${D}/${systemd_system_unitdir}/pldmd.service.d
}

