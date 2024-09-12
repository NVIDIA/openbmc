
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
# GB200NVL Platform specifics
#
EXTRA_OEMESON:append = " -Dgpu-index-start=0 "
EXTRA_OEMESON:append = " -Dcommand-smbpbi-oob=disabled"

SYSTEMD_OVERRIDE:${PN} += "bmcweb-gb200nvl-hmc.conf:bmcweb.service.d/bmcweb-gb200nvl-hmc.conf"

