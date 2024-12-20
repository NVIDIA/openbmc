
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
     file://bmcweb-gb200nvl-hmc.conf \
     file://bmcweb-socket-gb200nvl-hmc.conf \
     "

# Flags to setup Redfish TLS-Auth opt-in.
# So by default https and authentication is disabled and can be enabled at runtime.
EXTRA_OEMESON:append = " -Dtls-auth-opt-in=enabled"
EXTRA_OEMESON:append = " -Dnvidia-oem-logservices=enabled"

# Set HTTPS port to 80
EXTRA_OEMESON:append = " -Dhttps_port=80"


EXTRA_OEMESON:append = " -Dredfish-system-uri-name=HGX_Baseboard_0"
EXTRA_OEMESON:append = " -Dredfish-manager-uri-name=HGX_BMC_0"
EXTRA_OEMESON:append = " -Dplatform-device-prefix=HGX_"
EXTRA_OEMESON:append = " -Dplatform-total-power-sensor-name=HGX_Chassis_0_TotalHSC_Power_0"
EXTRA_OEMESON:append = " -Dplatform-power-control-sensor-name=HGX_Chassis_0_TotalGPU_Power_0"
EXTRA_OEMESON:append = " -Dplatform-metrics-id=HGX_PlatformEnvironmentMetrics_0"
EXTRA_OEMESON:append = " -Dbios=disabled"
EXTRA_OEMESON:append = " -Dipmi=disabled"
EXTRA_OEMESON:append = " -Dpatch-ssh=disabled"
EXTRA_OEMESON:append = " -Dnic-configuration-update=disabled"
EXTRA_OEMESON:append = " -Ddhcp-configuration-update=disabled"
EXTRA_OEMESON:append = " -Dnvidia-oem-gb200nvl-properties=enabled"
EXTRA_OEMESON:append = " -Dplatform-gpu-name-prefix=GPU_ "
EXTRA_OEMESON:append = " -Dplatform-bmc-id=HGX_BMC_0"
EXTRA_OEMESON:append = " -Dnvidia-bootentryid=enabled"
EXTRA_OEMESON:append = " -Dnvidia-uuid-from-platform-chassis-name=enabled"
EXTRA_OEMESON += "-Dnvidia-oem-fw-update-staging=enabled"

# Disabling host os features
EXTRA_OEMESON:append = " -Dhost-os-features=disabled"
EXTRA_OEMESON:append = " -Dkvm=disabled"
EXTRA_OEMESON:append = " -Dntp=disabled"
EXTRA_OEMESON:append = " -Drmedia=disabled"
EXTRA_OEMESON:append = " -Dhost-iface=disabled "

EXTRA_OEMESON:append = " -Dnvidia-oem-device-status-from-file=enabled"
EXTRA_OEMESON:append = " -Dhealth-rollup-alternative=disabled"

# Enable Processor Debug Capabilities
EXTRA_OEMESON:append = " -Denable-debug-interface=enabled"

# Enable manufacturing test API for provisioning image
EXTRA_OEMESON:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'otp-provisioning', '-Dmanufacturing-test=enabled', '', d)}"

# Enable http (insecure), it may also help using Redfish Listener if there is SSL problem
EXTRA_OEMESON:append = " -Dinsecure-push-style-notification=enabled"

# Force event notification by http (insecure) as there is a SSL bug
EXTRA_OEMESON:append = " -Dforce-insecure-event-notification=enabled"

EXTRA_OEMESON:append = " -Dupdate-service-stage-location='/var/emmc/firmware-storage/staged-images/'"

# Enable fdr support
EXTRA_OEMESON:append = " -Dredfish-fdr-log=enabled"

# Enable DOT (Device Ownership Transfer) APIs
EXTRA_OEMESON:append = " -Dmanual-boot-mode-support=enabled "

# Enable shared memory support
EXTRA_OEMESON:append = " -Dshmem-platform-metrics=enabled "

# Assign the OEMDiagnosticDataType for System Dump
EXTRA_OEMESON:append = " -Doem-diagnostic-allowable-type='FPGA,ROT,FirmwareAttributes,HardwareCheckout'"

DEPENDS:append = " nvidia-shmem"
DEPENDS:append = " nvidia-tal"
RDEPENDS:${PN}:append = " nvidia-shmem"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fw_uuid_mapping.json"

FILES:${PN}:append = " \
    ${datadir}/${PN}/fw_uuid_mapping.json \
    ${systemd_system_unitdir}/bmcweb.service.d/bmcweb-gb200nvl-hmc.conf \
    ${systemd_system_unitdir}/bmcweb.socket.d/bmcweb-socket-gb200nvl-hmc.conf \
"

do_install:append() {
    install -d ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/fw_uuid_mapping.json ${D}${datadir}/${PN}/

    install -d ${D}${systemd_system_unitdir}/bmcweb.service.d
    install -m 0644 ${WORKDIR}/bmcweb-gb200nvl-hmc.conf ${D}${systemd_system_unitdir}/bmcweb.service.d/
    install -d ${D}${systemd_system_unitdir}/bmcweb.socket.d
    install -m 0644 ${WORKDIR}/bmcweb-socket-gb200nvl-hmc.conf ${D}${systemd_system_unitdir}/bmcweb.socket.d/
}

