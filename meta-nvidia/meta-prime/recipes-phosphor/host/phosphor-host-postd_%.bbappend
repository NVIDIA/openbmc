SRC_URI = "git://github.com/NVIDIA/phosphor-host-postd;protocol=https;branch=develop"
SRCREV = "fc70be7dd2c56dd65e6bcd8a5a46c8fb04b2248c"

DEPENDS += "phosphor-logging"

FILES:${PN} += "${datadir}/sbmrbootprogress/sbmr_boot_progress_code.json"

EXTRA_OEMESON:append = "-Dpcc=disabled "
EXTRA_OEMESON:append = "-Dsbmr-boot-progress=enabled "
EXTRA_OEMESON:append = "-Dsnoop-device=ipmi-ssif-postcodes "
EXTRA_OEMESON:append = "-Dpost-code-bytes=9 "
EXTRA_OEMESON:append = "-Dsystemd-target=multi-user.target "
EXTRA_OEMESON:append = "-Dsystemd-after-service=xyz.openbmc_project.State.Host.service "
