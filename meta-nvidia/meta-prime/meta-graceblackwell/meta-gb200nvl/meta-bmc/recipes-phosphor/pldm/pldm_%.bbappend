RDEPENDS:${PN} += " bash"
inherit systemd
EXTRA_OEMESON:append = " -Dsensor-polling-time=999 "

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fw_update_config.json \
                   file://check_cx7_pldm_state_association.sh \
                   file://check_cx7_pldm_state_association.service"

SYSTEMD_SERVICE:${PN}:append = " check_cx7_pldm_state_association.service"

do_install:append() {
    rm -f ${D}${datadir}/pldm/fw_update_config.json

    install -m 0644 ${WORKDIR}/fw_update_config.json ${D}${datadir}/pldm/
    install -m 0755 ${WORKDIR}/check_cx7_pldm_state_association.sh ${D}${bindir}/
    install -m 0644 ${WORKDIR}/check_cx7_pldm_state_association.service ${D}${nonarch_base_libdir}/systemd/system/
}

