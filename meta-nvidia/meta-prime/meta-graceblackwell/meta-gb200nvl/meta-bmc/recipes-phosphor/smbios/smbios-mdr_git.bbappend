#
# Disable CPU and Memory information from SMBIOS
# Because this is managed by the HMC
#
EXTRA_OEMESON:append = " -Dcpu-dbus-chassisiface=disabled"
EXTRA_OEMESON:append = " -Dprocmod-dbus=disabled"