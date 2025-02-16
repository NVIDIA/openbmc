# HMC information
EXTRA_OEMESON:append = " -Dlogging-level=info"
EXTRA_OEMESON:append = " -Dhmc-hostname='172.31.13.251'"
EXTRA_OEMESON:append = " -Dhmc-port=80"
EXTRA_OEMESON:append = " -Dcpu-erot-num=2"

# Public key for disabling Device Ownership Transfer
# Key was taken from Debug Token Signing Service
# TODO: May want to move the key to a PEM file installed with image
EXTRA_OEMESON:append = " -Ddot-public-key='\
-----BEGIN PUBLIC KEY-----\
\nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEVQDSoBJP0fozRr45HtiIBzxwRAv9EbH/\
\nxmfxYTssmGq00bgmuT3ZKYfXY6GaiXznUE4x5LBTc4/tFxBZnxh1Ji2uDwncCkXE\
\nGsG4fTzkxmZ4xUjtV7HR6EUj8b6izggb\
\n-----END PUBLIC KEY-----\
'"

PACKAGECONFIG:append = " disable-cpu-dot"

PACKAGECONFIG[disable-cpu-dot] = "-Ddisable-cpu-dot=enabled, -Ddisable-cpu-dot=disabled"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'disable-cpu-dot', \
                                               'xyz.openbmc_project.disabledot.service', \
                                               '', d)}"
