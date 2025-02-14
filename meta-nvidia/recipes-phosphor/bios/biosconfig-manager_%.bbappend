FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/bios-settings-mgr;protocol=https;branch=develop"
SRCREV = "d2d16b713553b7638809fe1cebe1f03c995ff869"

RDEPENDS:${PN} += " host-iface "
SYSTEMD_SERVICE:${PN}:remove = "xyz.openbmc_project.biosconfig_password.service"
