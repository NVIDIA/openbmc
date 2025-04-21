FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/pldm;protocol=https;branch=Core-24.09-1_br"
SRCREV = "5044e96f83490e770d58c403eed6383b28e85065"

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
