FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/pldm;protocol=https;branch=develop"
SRCREV = "07cae8c71710cadca25325ec4910bd584be7b252"

DEPENDS += "nvidia-tal"
DEPENDS += "libmctp"
DEPENDS += "libpldm"

EXTRA_OEMESON += " \
    -Dlibpldmresponder=disabled \
    -Dtests=disabled \
    -Dnon-pldm=enabled \
    -Doem-ibm=disabled \
    -Doem-ampere=disabled \
    -Dsoftoff=disabled \
    -Domit-heartbeat=disabled \
    -Doem-nvidia=enabled \
    -Ddebug-token=enabled \
    -Dfw-update-skip-package-size-check=enabled \
    -Dinstance-id-expiration-interval=15 \
    -Dresponse-time-out=4800 \
    -Dpldm-package-verification=disabled \
    "
EXTRA_OEMESON:append = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' -Ddebug-token=disabled ', ' -Dfw-debug=enabled ', d)}"
