FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

BIN = "fpga_ready_init.sh"

SRC_URI:append = " file://${BIN} \
                   file://fpga1_ready.sh \
                   file://systemd/nvidia-fpga-ready-init.service \
                   file://systemd/nvidia-fpga-ready.conf \
                   file://systemd/nvidia-fpga-notready.conf \
                   file://systemd/nvidia-fpga1-ready.service \
                   file://systemd/nvidia-fpga1-notready.service \
                 "

SYSTEMD_SERVICE:${PN}:remove = " nvidia-fpga-ready-monitor.service"

SYSTEMD_SERVICE:${PN}:append = " nvidia-fpga-ready-init.service"
SYSTEMD_SERVICE:${PN}:append = " nvidia-fpga1-ready.service"
SYSTEMD_SERVICE:${PN}:append = " nvidia-fpga1-notready.service"

SYSTEMD_OVERRIDE:${PN}:append = "systemd/nvidia-fpga-ready.conf:nvidia-fpga-ready.target.d/nvidia-fpga-ready.conf "
SYSTEMD_OVERRIDE:${PN}:append = "systemd/nvidia-fpga-notready.conf:nvidia-fpga-notready.target.d/nvidia-fpga-notready.conf "

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/${BIN} ${D}${bindir}/${BIN}
    install -m 0755 ${WORKDIR}/fpga1_ready.sh ${D}${bindir}

    rm -f ${D}${nonarch_base_libdir}/systemd/system/nvidia-fpga-ready-monitor.service
    install -m 0644 ${WORKDIR}/systemd/nvidia-fpga-ready-init.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/nvidia-fpga1-ready.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/nvidia-fpga1-notready.service ${D}${nonarch_base_libdir}/systemd/system/
}
