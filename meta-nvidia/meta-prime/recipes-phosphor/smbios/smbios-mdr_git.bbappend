SRC_URI = "git://github.com/NVIDIA/smbios-mdr;protocol=https;branch=develop"
SRCREV = "d608220ba01c2009b3caba55bf186453d0e29943"

# cpuinfo collects CPU information through the Intel PECI interface
PACKAGECONFIG:remove = " cpuinfo"
# enable IPMI blob /smbios
PACKAGECONFIG:append = " smbios-ipmi-blob"
PACKAGECONFIG:append = " firmware-inventory-dbus"
PACKAGECONFIG:append = " tpm-dbus"

EXTRA_OEMESON:append = " -Dnvidia='true'"
EXTRA_OEMESON:append = " -Dexpose-inventory=true"
EXTRA_OEMESON:append = " -Dfirmware-component-name-bmc='BMC Firmware'"
EXTRA_OEMESON:append = " -Dfirmware-component-name-bios='System ROM'"
EXTRA_OEMESON:append = " -Dfirmware-component-name-fpga='HGX_FW_FPGA'"
