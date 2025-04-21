RDEPENDS:${PN} += " bash"
inherit systemd
EXTRA_OEMESON:append = " -Dsensor-polling-time=999 "

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fw_update_config.json \
                   file://pldmd.conf \
                 "

FILES:${PN}:append = " ${nonarch_base_libdir}/systemd/system/pldmd.service.d/pldmd.conf "

do_install:append() {
    rm -f ${D}${datadir}/pldm/fw_update_config.json

    mkdir -p ${D}${nonarch_base_libdir}/systemd/system/pldmd.service.d

    install -m 0644 ${WORKDIR}/fw_update_config.json ${D}${datadir}/pldm/
    install -m 0644 ${WORKDIR}/pldmd.conf ${D}${nonarch_base_libdir}/systemd/system/pldmd.service.d
}

