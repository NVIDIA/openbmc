FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/bios-settings-mgr;protocol=https;branch=develop"
SRCREV = "4c19b408bae8a9c34002b1c1cdc1b6da6f02252b"

RDEPENDS:${PN} += " host-iface "
SYSTEMD_SERVICE:${PN}:remove = "xyz.openbmc_project.biosconfig_password.service"
