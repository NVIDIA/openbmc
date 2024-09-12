FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
           file://setup_pciechip.sh \
           file://cleanup_pciechip.sh \
           file://pciechip.json \
           file://copy_chip_binary.sh \
           file://fw_status_precheck.sh \
           file://systemd/com.Nvidia.FWStatus.conf \
        "

EXTRA_OEMESON:append = " -DDEBUG_TOKEN_SUPPORT=enabled"
EXTRA_OEMESON:append = " -DDEBUG_TOKEN_INSTALL_SUPPORTED_MODEL=Nvidia:DebugTokenInstall:76910DFA1E4C11ED861D0242AC120002"
EXTRA_OEMESON:append = " -DDEBUG_TOKEN_ERASE_SUPPORTED_MODEL=Nvidia:DebugTokenErase:76910DFA1E4C11ED861D0242AE52A53E"
EXTRA_OEMESON:append = " -DJAMPLAYER_SUPPORT=enabled -DJAMPLAYER_SUPPORTED_MODEL='Nvidia:ALTERA_FPGA:f65ec98a70e84e3da6c18d9f2b51d3e0' "
EXTRA_OEMESON:append = " -DJAMPLAYER_NAME='HGX_FW_CPLD_0'"
EXTRA_OEMESON:append = " -DGPU_OCP_RECOVERY_SUPPORT=enabled"
EXTRA_OEMESON:append = " -DGPU_OCP_RECOVERY_SUPPORTED_MODEL=Nvidia:OCPRecovery:CD3D96D8F70711EEBB65CFE7103AC1AC"
EXTRA_OEMESON:append = " -DGPU_OCP_RECOVERY_TIMEOUT=480"
EXTRA_OEMESON:append = " -DGLACIER_RECOVERY_SUPPORT=enabled"
EXTRA_OEMESON:append = " -DGLACIER_RECOVERY_SUPPORTED_MODEL=Nvidia:GlacierRecovery:DBC2D178F70711EEBB65CFE7103AC1AC"
EXTRA_OEMESON:append = " -DGLACIER_RECOVERY_TIMEOUT=360"
EXTRA_OEMESON:append = " -DFWSTATUS_SUPPORT=enabled"

SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.DebugTokenInstall.Updater.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.DebugTokenErase.Updater.service"
SYSTEMD_SERVICE:${PN}:append = " debug-token-update@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.Jamplayer.service jamplayer-flash@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.MTD.Updater.pciechip.service mtd-update@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.OCP.GPU.Recovery.service"
SYSTEMD_SERVICE:${PN}:append = " ocp-recovery@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.GlacierRecovery.Updater.service"
SYSTEMD_SERVICE:${PN}:append = " glacier-recovery@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.FWStatus.service"

EXTRA_OEMESON:append = " -DMTD_UPDATER_SUPPORT=enabled -DPCIECHIP_SUPPORTED_MODEL='Nvidia:PCIECHIP_MTD:9a38e3da0f6a4ca99e68ea87dfd8d852' "
SYSTEMD_SERVICE:${PN}:append = " cpu_is_on.service cpu_is_off.service"
FILES:${PN}:append = " ${datadir}/mtd_targets/pciechip.json "

SYSTEMD_OVERRIDE:${PN}:append = "systemd/com.Nvidia.FWStatus.conf:com.Nvidia.FWStatus.service.d/com.Nvidia.FWStatus.conf "

do_install:append() {
        install -m 0755 ${WORKDIR}/setup_pciechip.sh ${D}${bindir}/
        install -m 0755 ${WORKDIR}/cleanup_pciechip.sh ${D}${bindir}/
        install -m 0755 ${WORKDIR}/copy_chip_binary.sh ${D}${bindir}/
        install -m 0755 ${WORKDIR}/fw_status_precheck.sh ${D}/${bindir}/
        install -d ${D}${datadir}/mtd_targets
        install -m 0644 ${WORKDIR}/pciechip.json ${D}${datadir}/mtd_targets/
}

