FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# KWS-7327
SRC_URI:remove = "file://nvidia-usb-monitor.service"
SYSTEMD_SERVICE:${PN}:remove = "nvidia-usb-monitor.service"

do_install:append() {
    rm -f ${D}${bindir}/usb_status_monitor.sh
}
