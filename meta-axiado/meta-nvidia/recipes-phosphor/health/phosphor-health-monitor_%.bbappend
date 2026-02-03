FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# KWS-6560
SRC_URI += "file://bmc_health_config.json"

do_install:append() {
    install -d ${D}/${sysconfdir}/healthMon/
    install -m 0644 ${UNPACKDIR}/bmc_health_config.json ${D}/${sysconfdir}/healthMon/
}
