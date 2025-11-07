SRC_URI = "git://github.com/NVIDIA/bmcweb;protocol=https;branch=develop"
SRCREV = "fad9ef5781c3e9bbf9e31a1b1e4683162636c98e"

EXTRA_OEMESON:append = " -Dnvidia-oem-pmc=enabled"
EXTRA_OEMESON:append = " -Dbmcweb-logging=error"
EXTRA_OEMESON:append = " -Dredfish-manager-uri-name=PMC_0"
EXTRA_OEMESON:append = " -Dplatform-chassis-name=PowerShelf_0"
EXTRA_OEMESON:append = " -Dplatform-power-control-sensor-name=RackPower_0"
