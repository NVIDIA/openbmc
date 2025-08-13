FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
           file://setup_pciechip.sh \
           file://cleanup_pciechip.sh \
           file://pciechip.json \
           file://pciechip_power_watch.sh \
           file://fw_status_precheck.sh \
           file://update_last_state_change_time.sh \
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
EXTRA_OEMESON:append = " -DAP_IMAGE_VERIFICATION=enabled"
EXTRA_OEMESON:append = " -DVERIFY_PCIECHIP=enabled"
EXTRA_OEMESON:append = " -DPUBKEY_PCIECHIP=2d2d2d2d2d424547494e205055424c4943204b45592d2d2d2d2d0a4d485977454159484b6f5a497a6a3043415159464b344545414349445967414559305032347a55367161386678662f5275542f346a734b6d78485a4b302f67560a4979775077777235636f6174552f614b5630565538453563636b366c504d4f586d523939412b77424f5a5937446c5a7335734a4941334b47774e2f4c6743714e0a346235334661567a4e6958345a44336f6a554f6e5848374b31544f3530697a460a2d2d2d2d2d454e44205055424c4943204b45592d2d2d2d2d"
EXTRA_OEMESON:append = " -DVERIFY_JAMPLAYER=enabled"
EXTRA_OEMESON:append = " -DPUBKEY_JAMPLAYER=2d2d2d2d2d424547494e205055424c4943204b45592d2d2d2d2d0a4d485977454159484b6f5a497a6a3043415159464b34454541434944596741456c5838784271384f6632574c6e59514b43484565462f465151697550715a57530a7647547a6859586a774134334b546e304d5172303072437747422f44476a635179424f2f4d737230774c49384b7a585330396f6251457473614a68726e4f4d760a773046686f586749584a6e625975657842324d65324f4c646a6655694c4543570a2d2d2d2d2d454e44205055424c4943204b45592d2d2d2d2d"

EXTRA_OEMESON:append = " -DSPI_WRITE_PROTECT_APP_SUPPORT=enabled"
EXTRA_OEMESON:append = " -DENABLE_IN_KERNEL_MCTP=enabled"

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
SYSTEMD_SERVICE:${PN}:append = " pciechip-power-watcher.service"

EXTRA_OEMESON:append = " -DMTD_UPDATER_SUPPORT=enabled -DPCIECHIP_SUPPORTED_MODEL='Nvidia:PCIECHIP_MTD:9a38e3da0f6a4ca99e68ea87dfd8d852' "
SYSTEMD_SERVICE:${PN}:append = " cpu_is_on.service cpu_is_off.service"
FILES:${PN}:append = " ${datadir}/mtd_targets/pciechip.json "

SYSTEMD_OVERRIDE:${PN}:append = "systemd/com.Nvidia.FWStatus.conf:com.Nvidia.FWStatus.service.d/com.Nvidia.FWStatus.conf "

do_install:append() {
        install -m 0755 ${UNPACKDIR}/setup_pciechip.sh ${D}${bindir}/
        install -m 0755 ${UNPACKDIR}/cleanup_pciechip.sh ${D}${bindir}/
        install -m 0755 ${UNPACKDIR}/pciechip_power_watch.sh ${D}${bindir}/
        install -m 0755 ${UNPACKDIR}/fw_status_precheck.sh ${D}/${bindir}/
        install -m 0755 ${UNPACKDIR}/update_last_state_change_time.sh ${D}/${bindir}/
        install -d ${D}${datadir}/mtd_targets
        install -m 0644 ${UNPACKDIR}/pciechip.json ${D}${datadir}/mtd_targets/
}

