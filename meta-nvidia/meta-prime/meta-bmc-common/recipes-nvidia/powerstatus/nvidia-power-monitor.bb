SUMMARY = "NVIDIA Power Status Monitor"
PR = "r1"
PV = "0.1"

# FIXME: once having the correct license info for upstream
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS += "libgpiod"
DEPENDS += "systemd"
RDEPENDS:${PN} = "nvidia-mc-lib nvidia-event-logs"

S = "${WORKDIR}"

FILESEXTRAPATHS:append := ":${THISDIR}/files"

SYSDSVCS = "nvidia-power-monitor.service \
            nvidia-shutdown-ok-monitor.service \
            nvidia-standby-power-monitor.service \
            nvidia-sync-host-req-transition-to-off.service \
            "

SRC_URI = "file://power_status_monitor.sh \
           file://power_status_inc.sh \
           file://shutdown_ok_monitor.sh \
           file://standby_power_status_monitor.sh \
           file://nvidia-sync-host-req-transition.sh \
          "

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "${SYSDSVCS}"
SYSTEMD_LINK_${PN} += "${@compose_list(d, 'FMT', 'PWRSTS_SERVICE')}"

do_install() {
    install -d ${D}${bindir}
    install -d ${D}${systemd_system_unitdir}
    install -m 0755 ${WORKDIR}/power_status_monitor.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/power_status_inc.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/shutdown_ok_monitor.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/standby_power_status_monitor.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/nvidia-sync-host-req-transition.sh ${D}${bindir}/
}

