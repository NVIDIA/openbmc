#
# Disable CPU and Memory information from SMBIOS
# Because this is managed by the HMC
#
EXTRA_OEMESON:append = " -Dcpu-dbus=disabled"
EXTRA_OEMESON:append = " -Ddimm-dbus=disabled"
EXTRA_OEMESON:append = " -Dprocmod-dbus=disabled"