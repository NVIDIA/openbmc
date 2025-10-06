SRC_URI = "git://github.com/NVIDIA/phosphor-host-postd;protocol=https;branch=develop"
SRCREV = "d5d212e52e32a38c8a93648d921da3b019101c14"

DEPENDS += "phosphor-logging"
DEPENDS += "libusb1"

EXTRA_OEMESON:append = " -Dsystemd-target=multi-user.target"
EXTRA_OEMESON:append = " -Dsystemd-after-service=xyz.openbmc_project.State.Host.service"
