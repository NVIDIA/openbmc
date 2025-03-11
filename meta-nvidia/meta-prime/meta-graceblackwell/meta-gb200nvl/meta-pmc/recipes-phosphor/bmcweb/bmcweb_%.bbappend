SRC_URI = "git://github.com/NVIDIA/bmcweb;protocol=https;branch=develop"
SRCREV = "d4d00f8bc0cf8d3335a812bcf064dd28dbafc78b"

EXTRA_OEMESON:append = " -Dnvidia-oem-pmc=enabled"
EXTRA_OEMESON:append = " -Dbmcweb-logging=error"
EXTRA_OEMESON:append = " -Dredfish-manager-uri-name=PMC_0"
EXTRA_OEMESON:append = " -Dplatform-chassis-name=PowerShelf"
