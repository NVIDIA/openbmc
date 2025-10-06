SRC_URI = "git://github.com/NVIDIA/bmcweb;protocol=https;branch=develop"
SRCREV = "d4a30ab1508cd88cd39be347146680d0215badd8"

EXTRA_OEMESON:append = " -Dnvidia-oem-pmc=enabled"
EXTRA_OEMESON:append = " -Dbmcweb-logging=error"
EXTRA_OEMESON:append = " -Dredfish-manager-uri-name=PMC_0"
EXTRA_OEMESON:append = " -Dplatform-chassis-name=PowerShelf_0"
EXTRA_OEMESON:append = " -Dplatform-power-control-sensor-name=RackPower_0"
