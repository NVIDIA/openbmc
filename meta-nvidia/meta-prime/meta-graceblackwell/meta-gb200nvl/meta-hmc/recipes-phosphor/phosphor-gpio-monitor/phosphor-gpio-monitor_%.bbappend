FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
           file://sec_fpga_fault_detect.sh \
           file://sec-fpga-status@.service \
           file://phosphor-multi-gpio-monitor.json \
           "

do_install:append() {
        install -m 0644 ${WORKDIR}/phosphor-multi-gpio-monitor.json ${D}/usr/share/phosphor-gpio-monitor/phosphor-multi-gpio-monitor.json
        install -m 0755 ${WORKDIR}/sec_fpga_fault_detect.sh ${D}${bindir}/
        install -m 0644 ${WORKDIR}/sec-fpga-status@.service ${D}${base_libdir}/systemd/system/
}

FILES:${PN}-monitor:append= " \
         ${base_libdir}/systemd/system/sec-fpga-status@.service \
        "
