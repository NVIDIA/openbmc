SRC_URI = "git://github.com/NVIDIA/phosphor-host-postd;protocol=https;branch=develop"
SRCREV = "dc8e0c93e317df24366c993e258f521ee6a755ab"

DEPENDS += "phosphor-logging"
DEPENDS += "libusb1"

EXTRA_OEMESON:append = " -Dsystemd-target=multi-user.target"
EXTRA_OEMESON:append = " -Dsystemd-after-service=xyz.openbmc_project.State.Host.service"
