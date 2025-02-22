FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://create_eeprom_devices.sh \
                   file://bmc_ready.sh \
                   file://multi_module_detection.sh \
                   file://common_platform_var.conf \
                   file://usb_status_monitor.sh \
                   file://nvidia-usb-monitor.service \
                 "  
SRC_URI:append:gb200nvl-bmc-ut3 = " file://gb200nvl-bmc-ut3/create_eeprom_devices.sh \
                                    file://gb200nvl-bmc-ut3/bmc_ready.sh"

SYSTEMD_SERVICE:${PN}:append = " nvidia-usb-monitor.service"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/bmc_ready.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/create_eeprom_devices.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/multi_module_detection.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/common_platform_var.conf ${D}/etc/default/platform_var.conf
    install -m 0755 ${WORKDIR}/usb_status_monitor.sh ${D}/${bindir}/
}
