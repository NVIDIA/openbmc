SRC_URI = "git://github.com/NVIDIA/smbios-mdr;protocol=https;branch=develop"
SRCREV = "522e61818add039ec8a54fb1f1dde84a7bbd2bc7"

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
