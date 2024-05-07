FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://create_eeprom_devices.sh \
                   file://bmc_ready.sh \
                   file://multi_module_detection.sh \
                   file://common_platform_var.conf \
                 "  

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/bmc_ready.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/create_eeprom_devices.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/multi_module_detection.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/common_platform_var.conf ${D}/etc/default/platform_var.conf
}