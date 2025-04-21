SRC_URI = "git://github.com/NVIDIA/phosphor-host-postd;protocol=https;branch=Core-24.09-1_br"
SRCREV = "79289060bee09a395ea750f9b1925dffd7b2580c"

DEPENDS += "phosphor-logging"

FILES:${PN} += "${datadir}/sbmrbootprogress/sbmr_boot_progress_code.json"

EXTRA_OEMESON:append = "-Dpcc=disabled "
EXTRA_OEMESON:append = "-Dsbmr-boot-progress=enabled "
EXTRA_OEMESON:append = "-Dsnoop-device=ipmi-ssif-postcodes "
EXTRA_OEMESON:append = "-Dpost-code-bytes=9 "
EXTRA_OEMESON:append = "-Dsystemd-target=multi-user.target "
EXTRA_OEMESON:append = "-Dsystemd-after-service=xyz.openbmc_project.State.Host.service "
