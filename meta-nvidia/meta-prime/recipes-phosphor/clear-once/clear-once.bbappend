FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://clear-once.service"

SYSTEMD_SERVICE:${PN} += "clear-once.service"