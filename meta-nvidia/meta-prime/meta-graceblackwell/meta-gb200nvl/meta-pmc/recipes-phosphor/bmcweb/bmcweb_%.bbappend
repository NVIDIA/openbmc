SRC_URI = "git://github.com/NVIDIA/bmcweb;protocol=https;branch=develop"
SRCREV = "41f7a2f806509f1afc8f8667010ec3e7895e09dc"

EXTRA_OEMESON:append = " -Dnvidia-oem-pmc=enabled"
EXTRA_OEMESON:append = " -Dbmcweb-logging=error"
EXTRA_OEMESON:append = " -Dredfish-manager-uri-name=PMC_0"
EXTRA_OEMESON:append = " -Dplatform-chassis-name=PowerShelf"
