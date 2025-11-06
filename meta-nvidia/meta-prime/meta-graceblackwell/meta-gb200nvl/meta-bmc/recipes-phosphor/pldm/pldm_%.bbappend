RDEPENDS:${PN} += " bash"
inherit systemd
EXTRA_OEMESON:append = " -Dsensor-polling-time=999 "
EXTRA_OEMESON:append = " -Dpldm-package-verification=integrity "

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fw_update_config_cx7.json \
                   file://fw_update_config_cx8.json \
                   file://pldmd.conf \
                 "

FILES:${PN}:append = " ${nonarch_base_libdir}/systemd/system/pldmd.service.d/pldmd.conf "

do_install:append() {
    rm -f ${D}${datadir}/pldm/fw_update_config.json

    mkdir -p ${D}${nonarch_base_libdir}/systemd/system/pldmd.service.d

    install -m 0644 ${UNPACKDIR}/fw_update_config_cx7.json ${D}${datadir}/pldm/
    install -m 0644 ${UNPACKDIR}/fw_update_config_cx8.json ${D}${datadir}/pldm/
    install -m 0644 ${UNPACKDIR}/pldmd.conf ${D}${nonarch_base_libdir}/systemd/system/pldmd.service.d

    # Create symbolic link from /usr/share/pldm/fw_update_config.json to /etc/default/pldm/fw_update_config.json
    ln -sf /etc/default/pldm/fw_update_config.json ${D}${datadir}/pldm/fw_update_config.json
}

