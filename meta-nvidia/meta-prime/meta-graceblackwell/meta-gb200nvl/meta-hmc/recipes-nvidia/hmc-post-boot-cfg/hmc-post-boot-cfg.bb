SUMMARY = "NVIDIA E4830 HMC Post-boot Configuration"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://fpga_power_sequence.sh \
           file://multi_module_detection.sh \
           file://hmc_ready.sh \
           file://i2c-slave-config.sh \
           file://i2c-boot-progress.sh \
           file://hmc-boot-complete.service \
           file://common_platform_var.conf \
           file://cg1_set_module_temp_sensor_threshold.sh \
           file://temperature-threshold-cfg.service \
           file://bind_expanders.sh \
           file://bind_expanders.service \
           "

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash nvidia-mc-lib nvidia-event-logs"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        hmc-boot-complete.service \
        temperature-threshold-cfg.service \
        bind_expanders.service \
        "

do_install() {
    install -d ${D}/${bindir}
    install -d ${D}/etc/default/
    install -m 0755 ${WORKDIR}/fpga_power_sequence.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/multi_module_detection.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/hmc_ready.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/i2c-slave-config.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/i2c-boot-progress.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/bind_expanders.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/common_platform_var.conf ${D}/etc/default/platform_var.conf

    install -m 0755 ${WORKDIR}/cg1_set_module_temp_sensor_threshold.sh ${D}/${bindir}/set_module_temp_sensor_threshold.sh
}

