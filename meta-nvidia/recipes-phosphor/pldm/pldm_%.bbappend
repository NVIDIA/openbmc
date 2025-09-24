FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/pldm;protocol=https;branch=develop"
SRCREV = "4e8bcf78626d10a8309c620019520593b55b072b"

DEPENDS += "nvidia-tal"
DEPENDS += "libmctp"
DEPENDS += "libpldm"

EXTRA_OEMESON += " \
    -Dlibpldmresponder=disabled \
    -Dtests=disabled \
    -Dnon-pldm=enabled \
    -Doem-nvidia=enabled \
    -Ddebug-token=enabled \
    -Dfw-update-skip-package-size-check=enabled \
    -Dinstance-id-expiration-interval=15 \
    -Dresponse-time-out=4800 \
    -Dpldm-package-verification=integrity \
    "
EXTRA_OEMESON:append = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' -Ddebug-token=disabled ', ' -Dfw-debug=enabled ', d)}"
