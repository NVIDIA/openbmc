FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fw_update_config.json "

do_install:append() {
    rm -f ${D}${datadir}/pldm/fw_update_config.json

    install -m 0644 ${WORKDIR}/fw_update_config.json ${D}${datadir}/pldm/
}

