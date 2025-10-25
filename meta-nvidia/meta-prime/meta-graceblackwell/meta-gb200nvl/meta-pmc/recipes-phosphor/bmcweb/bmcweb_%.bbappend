SRC_URI = "git://github.com/NVIDIA/bmcweb;protocol=https;branch=develop"
SRCREV = "2e6c03bc0759dd963a69d509223f8b7619194f4f"

EXTRA_OEMESON:append = " -Dnvidia-oem-pmc=enabled"
EXTRA_OEMESON:append = " -Dbmcweb-logging=error"
EXTRA_OEMESON:append = " -Dredfish-manager-uri-name=PMC_0"
EXTRA_OEMESON:append = " -Dplatform-chassis-name=PowerShelf_0"
EXTRA_OEMESON:append = " -Dplatform-power-control-sensor-name=RackPower_0"
