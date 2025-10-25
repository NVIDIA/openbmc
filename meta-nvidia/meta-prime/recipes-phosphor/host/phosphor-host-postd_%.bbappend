SRC_URI = "git://github.com/NVIDIA/phosphor-host-postd;protocol=https;branch=develop"
SRCREV = "077398215fe16618a693df2fa79516a8bdc92c82"

DEPENDS += "phosphor-logging"
DEPENDS += "libusb1"

FILES:${PN} += "${datadir}/sbmrbootprogress/sbmr_boot_progress_code.json"

EXTRA_OEMESON:append = "-Dpcc=disabled "
EXTRA_OEMESON:append = "-Dsbmr-boot-progress=enabled "
EXTRA_OEMESON:append = "-Dsnoop-device=ipmi-ssif-postcodes "
EXTRA_OEMESON:append = "-Dpost-code-bytes=9 "
EXTRA_OEMESON:append = "-Dsystemd-target=multi-user.target "
EXTRA_OEMESON:append = "-Dsystemd-after-service=xyz.openbmc_project.State.Host.service "
