SRC_URI = "git://github.com/NVIDIA/smbios-mdr;protocol=https;branch=Core-24.09-1_br"
SRCREV = "f43e34cfa5eb143df8b51e4cdecb93f6072231ca"

# cpuinfo collects CPU information through the Intel PECI interface
PACKAGECONFIG:remove = " cpuinfo"
# enable IPMI blob /smbios
PACKAGECONFIG:append = " smbios-ipmi-blob"
EXTRA_OEMESON:append = " -Dnvidia='true'"
EXTRA_OEMESON:append = " -Dexpose-inventory=true"
EXTRA_OEMESON:append = " -Dfirmware-component-name-bmc='BMC Firmware'"
EXTRA_OEMESON:append = " -Dfirmware-component-name-bios='System ROM'"
EXTRA_OEMESON:append = " -Dfirmware-component-name-cx7='HGX_Full_FW_Image'"
EXTRA_OEMESON:append = " -Dfirmware-component-name-fpga='HGX_FW_FPGA'"
