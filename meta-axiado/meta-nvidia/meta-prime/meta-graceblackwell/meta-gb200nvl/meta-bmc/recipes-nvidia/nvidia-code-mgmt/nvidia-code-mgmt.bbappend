FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-KWS-7442-Add-Axiado-SCM-updater.patch"

SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' com.Nvidia.MTD.Updater.bmc.service ', '', d)}"
SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mtd-update@.service ', '', d)}"

EXTRA_OEMESON:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', '-DMTD_UPDATER_SUPPORT=enabled', '', d)}"
EXTRA_OEMESON:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', '-DBMC_SUPPORTED_MODEL=\'Nvidia:BMC_MTD:${BMC_UUID}\'', '', d)}"

SYSTEMD_SERVICE:${PN}:append = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' com.Axiado.SCM.Updater.bmc.service ', '', d)}"
SYSTEMD_SERVICE:${PN}:append = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' scm-update@.service ', '', d)}"

EXTRA_OEMESON:append = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' -DAXIADO_UPDATER_SUPPORT=enabled', '', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' -DBMC_SUPPORTED_MODEL=\'Axiado:BMC:${BMC_UUID}\'', '', d)}"

do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', 'true', 'false', d)}; then
         rm ${D}${systemd_unitdir}/system/com.Nvidia.MTD.Updater.bmc.service
         rm ${D}${systemd_unitdir}/system/mtd-update@.service

         install -m 0644 ${S}/services/com.Axiado.SCM.Updater.bmc.service ${D}${systemd_unitdir}/system/
         install -m 0644 ${S}/services/scm-update@.service ${D}${systemd_unitdir}/system/
         install -m 0755 ${S}/scm-update.sh ${D}${bindir}/
    fi
}
