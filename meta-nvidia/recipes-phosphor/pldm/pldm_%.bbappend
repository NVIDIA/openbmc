FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/pldm;protocol=https;branch=develop"
SRCREV = "75b88e6256fe1622058d1633f9694385cc98e959"

DEPENDS += "nvidia-tal"
DEPENDS += "libmctp"

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
