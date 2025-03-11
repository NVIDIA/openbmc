FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/pldm;protocol=https;branch=develop"
SRCREV = "b952063120d24c2368e3f10c2f4af83002472350"

DEPENDS += "nvidia-tal"
DEPENDS += "libmctp"

EXTRA_OEMESON += " \
    -Dlibpldmresponder=disabled \
    -Dtests=disabled \
    -Dnon-pldm=enabled \
    -Doem-nvidia=enabled \
    -Ddebug-token=enabled \
    -Dfw-update-skip-package-size-check=enabled \
    -Dfw-debug=enabled \
    -Dinstance-id-expiration-interval=15 \
    -Dresponse-time-out=4800 \
    -Dpldm-package-verification=integrity \
    "
