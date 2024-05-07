RDEPENDS:${PN} += "bash"

# Only discover SPDM deices from MCTP control, as there is a race condition
# between PLDM and SPDM when it runs on SMBus and SPI
EXTRA_OEMESON:append = " -Ddiscovery_only_from_mctp_control=enabled"

