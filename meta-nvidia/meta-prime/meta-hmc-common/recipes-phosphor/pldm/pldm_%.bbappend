FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

EXTRA_OEMESON:append = " -Dlocal-eid-over-i2c=8 "

SRC_URI:append = " file://pldm-mctp-pcie.conf \
                 "
FILES:${PN}:append = " ${systemd_system_unitdir}/pldmd.service.d/* "
do_install:append() {
    install -d  ${D}/${systemd_system_unitdir}/pldmd.service.d
    install -m 0644 ${WORKDIR}/pldm-mctp-pcie.conf ${D}/${systemd_system_unitdir}/pldmd.service.d/pldm-mctp-pcie.conf
}

