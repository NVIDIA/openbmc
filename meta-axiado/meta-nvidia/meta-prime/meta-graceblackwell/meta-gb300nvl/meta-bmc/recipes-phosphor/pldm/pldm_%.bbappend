FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

EXTRA_OEMESON += "-Dsensor-polling-time=999"

SRC_URI += "file://fw_update_config.json"

do_install:append() {
    rm -f ${D}${datadir}/pldm/fw_update_config.json

    install -m 0644 ${UNPACKDIR}/fw_update_config.json ${D}${datadir}/pldm/
}

