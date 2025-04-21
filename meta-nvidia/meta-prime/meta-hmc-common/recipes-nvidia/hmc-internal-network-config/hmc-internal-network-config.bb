SUMMARY = "NVIDIA conf for statis IP assignment to usb0"
PR = "r1"
PV = "0.1"

# FIXME: when get correct license info
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

FILEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
            file://00-bmc-usb0.network \
           "

FILES:${PN} += " \
    ${sysconfdir}/systemd/network/00-bmc-usb0.network \
"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/00-bmc-usb0.network ${D}${sysconfdir}/systemd/network
}
