FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# redfish aggregation
EXTRA_OEMESON:append = " -Dredfish-aggregation=enabled"
EXTRA_OEMESON:append = " -Dredfish-aggregation-prefix=HGX "
EXTRA_OEMESON:append = " -Drfa-bmc-host-url=http://172.31.13.241:8080/"

#
# Platform specifics
#
# increasing update timeout to count for all psu updates
EXTRA_OEMESON:append = " -Dhost-iface-channel=hostusb0"
EXTRA_OEMESON:append = " -Dnvidia-oem-oberon-properties=enabled"
EXTRA_OEMESON:append = " -Dplatform-chassis-name=BMC_0 "   
EXTRA_OEMESON:append = " -Dredfish-system-uri-name=System_0 "
EXTRA_OEMESON:append = " -Dhost-auxpower-features=enabled "
EXTRA_OEMESON:append = " -Dredfish-manager-uri-name=BMC_0"
EXTRA_OEMESON:append = " -Dmanual-boot-mode-support=enabled "
EXTRA_OEMESON:append = " -Dhealth-rollup-alternative=enabled "

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append= " file://fw_mctp_mapping.json \
                  file://listener.conf \
                "

SYSTEMD_SERVICE:${PN} += " \
        redfishevent-listener.service \
        "

FILES:${PN}:append = " ${datadir}/${PN}/fw_mctp_mapping.json"

DEPENDS += " \
    phosphor-logging \
    phosphor-dbus-interfaces \
    sdbusplus \
"
do_install:append() {
    install -d ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/fw_mctp_mapping.json ${D}${datadir}/${PN}/fw_mctp_mapping.json
    install -d ${D}${datadir}/rf_listener/
    install -m 0644 ${WORKDIR}/listener.conf ${D}${datadir}/rf_listener/listener.conf
}
