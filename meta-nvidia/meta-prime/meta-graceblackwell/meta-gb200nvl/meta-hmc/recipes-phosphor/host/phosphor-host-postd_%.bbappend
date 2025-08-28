SRC_URI = "git://github.com/NVIDIA/phosphor-host-postd;protocol=https;branch=develop"
SRCREV = "fbf5c69723706e398063858137b0d77a0507de9c"

DEPENDS += "phosphor-logging"

EXTRA_OEMESON:append = " -Dsystemd-target=multi-user.target"
EXTRA_OEMESON:append = " -Dsystemd-after-service=xyz.openbmc_project.State.Host.service"
