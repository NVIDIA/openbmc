FILESEXTRAPATHS:append := "${THISDIR}/files:"

RDEPENDS:${PN} = " bash "

SRC_URI:append = " file://fw_status_precheck.sh \
                   file://cpldmanager.env \
                   file://systemd/hmc-ready.service \
                   file://systemd/hmc-notready.service \
                   file://systemd/com.Nvidia.FWStatus.service \
                  "

EXTRA_OEMESON:append = " -DDEBUG_TOKEN_SUPPORT=enabled"
EXTRA_OEMESON:append = " -DDEBUG_TOKEN_INSTALL_SUPPORTED_MODEL=Nvidia:DebugTokenInstall:76910DFA1E4C11ED861D0242AC120002"
EXTRA_OEMESON:append = " -DDEBUG_TOKEN_ERASE_SUPPORTED_MODEL=Nvidia:DebugTokenErase:76910DFA1E4C11ED861D0242AE52A53E"
EXTRA_OEMESON:append = " -DGLACIER_RECOVERY_SUPPORT=enabled"
EXTRA_OEMESON:append = " -DGLACIER_RECOVERY_SUPPORTED_MODEL=Nvidia:GlacierRecovery:DBC2D178F70711EEBB65CFE7103AC1AC"
EXTRA_OEMESON:append = " -DGLACIER_RECOVERY_TIMEOUT=180"
EXTRA_OEMESON:append = " -DFWSTATUS_SUPPORT=enabled"
EXTRA_OEMESON:append = " -DCPLD_SUPPORT=enabled"

EXTRA_OEMESON:append:gb200nvl-bmc-ut3 = " -DMTD_UPDATER_SUPPORT=enabled -DBMC_SUPPORTED_MODEL='Nvidia:BMC_MTD:678aac1134244bcc8a750bb622a3cfeb' "

SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.DebugTokenInstall.Updater.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.DebugTokenErase.Updater.service"
SYSTEMD_SERVICE:${PN}:append = " debug-token-update@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.GlacierRecovery.Updater.service"
SYSTEMD_SERVICE:${PN}:append = " glacier-recovery@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.FWStatus.service"
SYSTEMD_SERVICE:${PN}:append = " hmc-ready.service"
SYSTEMD_SERVICE:${PN}:append = " hmc-notready.service"
SYSTEMD_SERVICE:${PN}:append = " cpld-update@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.CPLD_N.Updater@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.CPLD_N.Starter.service"

SYSTEMD_SERVICE:${PN}:append:gb200nvl-bmc-ut3 = " com.Nvidia.MTD.Updater.bmc.service"
SYSTEMD_SERVICE:${PN}:append:gb200nvl-bmc-ut3 = " mtd-update@.service"

do_install:append:gb200nvl-bmc-ut3() {
    install -m 0644 ${S}/services/com.Nvidia.MTD.Updater.bmc.service ${D}${systemd_unitdir}/system/
    install -m 0644 ${S}/services/mtd-update@.service ${D}${systemd_unitdir}/system/
}
EXTRA_OEMESON:append = " -DVMEPLAYER_SUPPORT=enabled "
EXTRA_OEMESON:append = " -DVMEPLAYER0_SUPPORTED_MODEL='Nvidia:LATTICE_CPLD_0:0b8e8c7922a44b9ca22cdcc1f14a20eb' "
EXTRA_OEMESON:append = " -DVMEPLAYER1_SUPPORTED_MODEL='Nvidia:LATTICE_CPLD_1:cef4dc0f18e94423b83d572ffecc9408' "

SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.DebugTokenInstall.Updater.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.DebugTokenErase.Updater.service"
SYSTEMD_SERVICE:${PN}:append = " debug-token-update@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.Vmeplayer0.service com.Nvidia.Vmeplayer1.service vmeplayer-flash@.service "

SYSTEMD_SERVICE:${PN}:append = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' com.Nvidia.MTD.Updater.bmc.service ', '', d)}"
SYSTEMD_SERVICE:${PN}:append = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mtd-update@.service ', '', d)}"

python () {
    if bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', True, False, d):
        bmc_value = d.getVar('BMC_UUID')
        if bmc_value:
            bb.warn("Using erotless update for the BMC with UUID:%s" % bmc_value)
            d.appendVar('EXTRA_OEMESON', " -DMTD_UPDATER_SUPPORT=enabled -DBMC_SUPPORTED_MODEL='Nvidia:BMC_MTD:%s' " % bmc_value)
        else:
            bb.fatal("BMC_UUID is not set in local.conf file. Stopping the build.")
}

do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/systemd/system/com.Nvidia.FWStatus.service

    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/fw_status_precheck.sh ${D}/${bindir}/

    install -d ${D}${sysconfdir}/cpldupdate
    install -m 0644 ${WORKDIR}/cpldmanager.env ${D}${sysconfdir}/cpldupdate/cpldmanager.env

    install -m 0644 ${WORKDIR}/systemd/hmc-ready.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/hmc-notready.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/com.Nvidia.FWStatus.service ${D}${nonarch_base_libdir}/systemd/system/
}
