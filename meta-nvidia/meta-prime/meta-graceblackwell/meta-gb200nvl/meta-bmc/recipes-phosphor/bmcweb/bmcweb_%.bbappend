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
EXTRA_OEMESON:append = " -Dnvidia-oem-gb200nvl-properties=enabled"
EXTRA_OEMESON:append = " -Dplatform-chassis-name=BMC_0 "   
EXTRA_OEMESON:append = " -Dredfish-system-uri-name=System_0 "
EXTRA_OEMESON:append = " -Dhost-auxpower-features=enabled "
EXTRA_OEMESON:append = " -Dredfish-manager-uri-name=BMC_0"
EXTRA_OEMESON:append = " -Dmanual-boot-mode-support=enabled "
EXTRA_OEMESON:append = " -Dhealth-rollup-alternative=enabled "
EXTRA_OEMESON:append = " -Dredfish-leak-detect=enabled "
EXTRA_OEMESON:append = " -Dnvidia-oem-openocd=enabled "
EXTRA_OEMESON:append = " -Dvm-nbdproxy=enabled "
EXTRA_OEMESON:append = " -Dvm-websocket=disabled "
EXTRA_OEMESON:append = " -Dplatform-metrics-id=PlatformEnvironmentMetrics_0"
EXTRA_OEMESON:append = " -Dhide-host-os-features-init-value=enabled "
# Enable shared memory support
EXTRA_OEMESON:append = " -Dshmem-platform-metrics=enabled "

DEPENDS:append = " nvidia-shmem"
DEPENDS:append = " nvidia-tal"
RDEPENDS:${PN}:append = " nvidia-shmem"

# Disable NSM raw command API
EXTRA_OEMESON:append = " -Dnsm-raw-command-enable=disabled "

EXTRA_OEMESON:append = " -Dnvidia-oem-fw-update-staging=enabled"

# Assign the OEMDiagnosticDataType for System Dump
EXTRA_OEMESON:append = " -Doem-diagnostic-allowable-type='FPGA,ROT,FirmwareAttributes,HardwareCheckout'"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append= " file://fw_uuid_mapping.json \
                  file://listener.conf \
                  file://mrd_PlatformEnvironmentMetrics.json \
                "

SRC_URI:append = " file://rot_chassis_properties_allowlist.json"

SYSTEMD_SERVICE:${PN} += " \
        redfishevent-listener.service \
        "

FILES:${PN}:append = " \
    ${datadir}/${PN}/fw_uuid_mapping.json \
    ${datadir}/${PN}/rot_chassis_properties_allowlist.json \
    ${datadir}/${PN}/mrd_PlatformEnvironmentMetrics.json \
"

DEPENDS += " \
    phosphor-logging \
    phosphor-dbus-interfaces \
    sdbusplus \
"
do_install:append() {
    install -d ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/fw_uuid_mapping.json ${D}${datadir}/${PN}/fw_uuid_mapping.json
    install -m 0644 ${WORKDIR}/rot_chassis_properties_allowlist.json ${D}${datadir}/${PN}/
    install -d ${D}${datadir}/rf_listener/
    install -m 0644 ${WORKDIR}/listener.conf ${D}${datadir}/rf_listener/listener.conf
    install -m 0644 ${WORKDIR}/mrd_PlatformEnvironmentMetrics.json ${D}${datadir}/${PN}/
}
