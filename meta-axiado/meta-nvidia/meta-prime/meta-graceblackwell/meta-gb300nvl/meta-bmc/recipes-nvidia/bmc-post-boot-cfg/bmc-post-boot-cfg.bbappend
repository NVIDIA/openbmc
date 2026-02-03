FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://create_eeprom_devices.sh \
            file://bmc_ready.sh \
            file://multi_module_detection.sh \
            file://common_platform_var.conf \
            file://usb_status_monitor.sh \
            file://nvidia-usb-monitor.service \
            "  

SYSTEMD_SERVICE:${PN} += "nvidia-usb-monitor.service"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${UNPACKDIR}/bmc_ready.sh ${D}/${bindir}/
    install -m 0755 ${UNPACKDIR}/create_eeprom_devices.sh ${D}/${bindir}/
    install -m 0755 ${UNPACKDIR}/multi_module_detection.sh ${D}/${bindir}/
    install -m 0755 ${UNPACKDIR}/common_platform_var.conf ${D}/etc/default/platform_var.conf
    install -m 0755 ${UNPACKDIR}/usb_status_monitor.sh ${D}/${bindir}/
}
