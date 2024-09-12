S = "${WORKDIR}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
           file://shutdown_ok_monitor.sh \
           file://check_cpu_boot_status.sh \
          "

do_install:append() {
    install -m 0755 ${WORKDIR}/check_cpu_boot_status.sh ${D}${bindir}/
}