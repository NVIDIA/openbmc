FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/bios-settings-mgr;protocol=https;branch=develop"
SRCREV = "02e41ff70a7ec5a98745bc497a1039969442971c"

RDEPENDS:${PN} += " host-iface "
SYSTEMD_SERVICE:${PN}:remove = "xyz.openbmc_project.biosconfig_password.service"
