FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/bios-settings-mgr;protocol=https;branch=develop"
SRCREV = "522e98dcf399553978624c8355214603764fe619"

RDEPENDS:${PN} += " host-iface "
SYSTEMD_SERVICE:${PN}:remove = "xyz.openbmc_project.biosconfig_password.service"
