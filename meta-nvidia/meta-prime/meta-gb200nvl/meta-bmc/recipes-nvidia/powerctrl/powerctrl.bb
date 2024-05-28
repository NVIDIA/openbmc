SUMMARY = "NVIDIA Power Control Services"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd
DEPENDS = "systemd"
RDEPENDS:${PN} = "bash nvidia-mc-lib"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

S = "${WORKDIR}"

SRC_URI = " \
      file://powerctrl.sh \
      file://stbypowerctrl.sh \
      file://nvidia-standby-poweroff.service \
      file://nvidia-standby-poweron.service \
      file://nvidia-aux-power.service \
      file://nvidia-aux-power-force.service \
      file://powerctrl-e4830-gh-bmc.sh \
     "

POWER_CONTROL_SCRIPT = "powerctrl.sh"
STANDBY_POWER_CONTROL_SCRIPT = "stbypowerctrl.sh"
POWER_CONTROL_SCRIPT:e4830-gh-bmc = "powerctrl-e4830-gh-bmc.sh"

PWRON_SERVICE = "host-poweron@.service"
PWRON_TGTFMT = "host-poweron@{0}.service"
PWRON_HOST_FMT = "../${PWRON_SERVICE}:obmc-host-startmin@{0}.target.requires/${PWRON_TGTFMT}"

PWROFF_SERVICE = "host-poweroff@.service"
PWROFF_TGTFMT = "host-poweroff@{0}.service"
PWROFF_HOST_FMT = "../${PWROFF_SERVICE}:obmc-chassis-hard-poweroff@{0}.target.requires/${PWROFF_TGTFMT}"

GRCPWROFF_SERVICE = "graceful-host-poweroff@.service"
GRCPWROFF_TGTFMT = "graceful-host-poweroff@{0}.service"
GRCPWROFF_HOST_FMT = "../${GRCPWROFF_SERVICE}:obmc-host-shutdown@{0}.target.requires/${GRCPWROFF_TGTFMT}"

STBYPWRON_SERVICE = "nvidia-standby-poweron.service"
STBYPWROFF_SERVICE = "nvidia-standby-poweroff.service"

RESET_SERVICE = "host-reset@.service"
RESET_TGTFMT = "host-reset@{0}.service"
RESET_HOST_FMT = "../${RESET_SERVICE}:obmc-host-force-warm-reboot@{0}.target.requires/${RESET_TGTFMT}"

GRCRESET_HOST_FMT = "../${RESET_SERVICE}:obmc-host-warm-reboot@{0}.target.requires/${RESET_TGTFMT}"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} += " \
        ${PWRON_SERVICE} \
        ${PWROFF_SERVICE} \
        ${GRCPWROFF_SERVICE} \
        ${STBYPWRON_SERVICE} \
        ${STBYPWROFF_SERVICE} \
        ${RESET_SERVICE} \
        power-brake-disabled.target \
        disable-power-brake.service \
        power-brake-enabled.target \
        enable-power-brake.service \
        "

SYSTEMD_SERVICE:${PN}:append = " \
       nvidia-aux-power.service \
       nvidia-aux-power-force.service  \
        "

SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'PWRON_HOST_FMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'PWROFF_HOST_FMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'GRCPWROFF_HOST_FMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'RESET_HOST_FMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'GRCRESET_HOST_FMT', 'OBMC_HOST_INSTANCES')}"

#The main control target requires these power targets
START_TMPL_CTRL = "obmc-chassis-poweron@.target"
START_TGTFMT_CTRL = "obmc-host-startmin@{0}.target"
START_INSTFMT_CTRL = "obmc-chassis-poweron@{0}.target"
START_FMT_CTRL = "../${START_TMPL_CTRL}:${START_TGTFMT_CTRL}.requires/${START_INSTFMT_CTRL}"
SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'START_FMT_CTRL', 'OBMC_CHASSIS_INSTANCES')}"

# Chassis off requires host off
STOP_TMPL_CTRL = "obmc-host-stop@.target"
STOP_TGTFMT_CTRL = "obmc-chassis-poweroff@{0}.target"
STOP_INSTFMT_CTRL = "obmc-host-stop@{0}.target"
STOP_FMT_CTRL = "../${STOP_TMPL_CTRL}:${STOP_TGTFMT_CTRL}.requires/${STOP_INSTFMT_CTRL}"
SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'STOP_FMT_CTRL', 'OBMC_CHASSIS_INSTANCES')}"

# Hard power off requires chassis off
HARD_OFF_TMPL_CTRL = "obmc-chassis-poweroff@.target"
HARD_OFF_TGTFMT_CTRL = "obmc-chassis-hard-poweroff@{0}.target"
HARD_OFF_INSTFMT_CTRL = "obmc-chassis-poweroff@{0}.target"
HARD_OFF_FMT_CTRL = "../${HARD_OFF_TMPL_CTRL}:${HARD_OFF_TGTFMT_CTRL}.requires/${HARD_OFF_INSTFMT_CTRL}"
SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'HARD_OFF_FMT_CTRL', 'OBMC_CHASSIS_INSTANCES')}"

do_install() {
    install -d ${D}/${bindir}
    install -d ${D}${systemd_system_unitdir}
    install -m 0755 ${S}/${POWER_CONTROL_SCRIPT} ${D}/${bindir}/powerctrl.sh
    install -m 0755 ${S}/${STANDBY_POWER_CONTROL_SCRIPT} ${D}/${bindir}/stbypowerctrl.sh
}



