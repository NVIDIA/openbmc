FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/bios-settings-mgr;protocol=https;branch=develop"
SRCREV = "4b9350461ba1b3754bc6e2cf71312035c5c5caf6"

RDEPENDS:${PN} += " host-iface "
SYSTEMD_SERVICE:${PN}:remove = "xyz.openbmc_project.biosconfig_password.service"
