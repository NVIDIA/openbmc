SUMMARY = "NVIDIA conf for static IP assignment to internal network interfaces"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

RDEPENDS:${PN} = "udev"

FILEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
            file://00-bmc-hmcusb0.network \
            file://00-bmc-hostusb0.network \
            file://90-hmc-net.rules \
            file://90-bmc-host-net.rules \
           "

SRC_URI:append:gb200nvl-bmc-ut3 = " file://91-bmc-ut3-usbnet.rules "

FILES:${PN} += " \
    ${sysconfdir}/systemd/network/00-bmc-hmcusb0.network \
    ${sysconfdir}/systemd/network/00-bmc-hostusb0.network \
    ${sysconfdir}/udev/rules.d/90-hmc-net.rules \
    ${sysconfdir}/udev/rules.d/90-bmc-host-net.rules \
"

FILES:${PN}:append:gb200nvl-bmc-ut3 = " ${sysconfdir}/udev/rules.d/91-bmc-ut3-usbnet.rules "

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = "systemd"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        ncsi-eth1-disable.service \
        "

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/00-bmc-hmcusb0.network ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/00-bmc-hostusb0.network ${D}${sysconfdir}/systemd/network

    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/90-hmc-net.rules ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/90-bmc-host-net.rules ${D}${sysconfdir}/udev/rules.d
}

do_install:append:gb200nvl-bmc-ut3() {
    install -m 0644 ${WORKDIR}/91-bmc-ut3-usbnet.rules ${D}${sysconfdir}/udev/rules.d
}
