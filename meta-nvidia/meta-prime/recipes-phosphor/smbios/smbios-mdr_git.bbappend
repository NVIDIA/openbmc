SRC_URI = "git://github.com/NVIDIA/smbios-mdr;protocol=https;branch=Core-24.09-1_br"
SRCREV = "f34c7756124ce2b10d8f00f4fb533372d85d1e6b"

# cpuinfo collects CPU information through the Intel PECI interface
PACKAGECONFIG:remove = " cpuinfo"
# enable IPMI blob /smbios
PACKAGECONFIG:append = " smbios-ipmi-blob"
EXTRA_OEMESON:append = " -Dnvidia='true'"
EXTRA_OEMESON:append = " -Dexpose-inventory=true"
EXTRA_OEMESON:append = " -Dfirmware-component-name-bmc='BMC Firmware'"
EXTRA_OEMESON:append = " -Dfirmware-component-name-bios='System ROM'"
EXTRA_OEMESON:append = " -Dfirmware-component-name-nic='Full FW Image'"
EXTRA_OEMESON:append = " -Dfirmware-component-name-fpga='HGX_FW_FPGA'"
