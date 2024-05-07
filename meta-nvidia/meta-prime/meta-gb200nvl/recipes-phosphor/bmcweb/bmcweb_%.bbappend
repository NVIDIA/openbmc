FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-meta-gh-TMP-avoid-some-HTTP-500-responses-in-Redfish.patch"

# Disable HostLogger in Redfish
EXTRA_OEMESON:append = " -Dredfish-host-logger=disabled"
EXTRA_OEMESON:append = " -Dnvidia-oem-properties=enabled"
EXTRA_OEMESON:append = " -Dredfish-system-faultlog-dump-log=enabled"
EXTRA_OEMESON:append = " -Dreset-bios-by-clear-nonvolatile=enabled"
EXTRA_OEMESON:append = " -Dhealth-rollup-alternative=enabled"
EXTRA_OEMESON:append = " -Dredfish-dbus-event=enabled"

# increasing update timeout to count for all psu updates
EXTRA_OEMESON:append = " -Dupdate-service-task-timeout=60"

EXTRA_OEMESON:append = " -Darray-bootprogress=enabled"
EXTRA_OEMESON:append = " -Dhost-iface=enabled "
EXTRA_OEMESON:append = " -Ddot-support=enabled"
EXTRA_OEMESON:append = " -Dnetwork-adapters-generic=enabled"
EXTRA_OEMESON:append = " -Dredfish-dump-log=enabled"

# Disable deprecated RF Thermal/Power subsystem
EXTRA_OEMESON:append = " -Dredfish-allow-deprecated-power-thermal=disabled "

#
# Platform specifics
#
EXTRA_OEMESON:append = " -Dplatform-system-id=System_0 "
EXTRA_OEMESON:append = " -Dplatform-bmc-id=BMC_0 "
EXTRA_OEMESON:append = " -Dplatform-total-power-sensor-name=Baseboard_0_TotalHSC_Power_0 "
EXTRA_OEMESON:append = " -Dplatform-power-control-sensor-name=Baseboard_0_TotalGPU_Power_0 "
EXTRA_OEMESON:append = " -Dplatform-metrics-id=PlatformEnvironmentMetrics_0 "
EXTRA_OEMESON:append = " -Dplatform-chassis-name=Baseboard_0 "
EXTRA_OEMESON:append = " -Dplatform-gpu-name-prefix=GPU_ "
EXTRA_OEMESON:append = " -Dgpu-index-start=0 "
