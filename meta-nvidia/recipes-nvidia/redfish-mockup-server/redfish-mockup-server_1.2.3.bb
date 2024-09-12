SUMMARY = "Redfish Mockup Server"
DESCRIPTION = "A simple Python 3.4 program that can be copied into a folder at the top of any Redfish mockup and can serve Redfish requests on the specified IP/port."
HOMEPAGE = "https://github.com/DMTF/Redfish-Mockup-Server"

SRC_URI = "git://github.com/DMTF/Redfish-Mockup-Server.git;branch=main;protocol=https"
SRC_URI[sha256sum] = "434f2a6c988f8f26fa98e1214101ff731f1fc8360afc3e178b716165ea9cd298"
SRCREV = "2d39eb14122337ceab0712a9610b1cd37c65f487"

LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE.md;md5=cee7a7694b5bf14bc9d3e0fbe78a64af"

inherit systemd

RDEPENDS:${PN} += "python3"
RDEPENDS:${PN} += "python3-setuptools"
RDEPENDS:${PN} += "python3-requests"
RDEPENDS:${PN} += "python3-grequests"
DEPENDS += "systemd"

S = "${WORKDIR}/git"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://redfish-mockup-server.service"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "redfish-mockup-server.service"

FILES:${PN}:append = " ${systemd_system_unitdir}"
FILES:${PN}:append = " ${systemd_system_unitdir}/redfish-mockup-server.service"
FILES:${PN}:append = " ${bindir}/redfish-mockup-server"
FILES:${PN}:append = " ${bindir}/redfish-mockup-server/*"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/redfish-mockup-server.service ${D}${systemd_system_unitdir}/
    install -d ${D}${bindir}
    install -d ${D}${bindir}/redfish-mockup-server
    install -m 0664 ${S}/*.py ${D}${bindir}/redfish-mockup-server/
}
