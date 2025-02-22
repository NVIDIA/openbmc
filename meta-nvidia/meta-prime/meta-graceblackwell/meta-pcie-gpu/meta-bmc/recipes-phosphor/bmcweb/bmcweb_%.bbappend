FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# redfish aggregation
#EXTRA_OEMESON:append = " -Dredfish-aggregation=enabled"
#EXTRA_OEMESON:append = " -Dredfish-aggregation-prefix=HGX "
#EXTRA_OEMESON:append = " -Drfa-bmc-host-url=http://172.31.13.241:8080/"

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

# Assign the OEMDiagnosticDataType for System Dump
EXTRA_OEMESON:append = " -Doem-diagnostic-allowable-type='FPGA,ROT,FirmwareAttributes,HardwareCheckout'"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append= " file://fw_uuid_mapping.json \
                "

FILES:${PN}:append = " ${datadir}/${PN}/fw_uuid_mapping.json"

DEPENDS += " \
    phosphor-logging \
    phosphor-dbus-interfaces \
    sdbusplus \
"
do_install:append() {
    install -d ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/fw_uuid_mapping.json ${D}${datadir}/${PN}/fw_uuid_mapping.json
}
