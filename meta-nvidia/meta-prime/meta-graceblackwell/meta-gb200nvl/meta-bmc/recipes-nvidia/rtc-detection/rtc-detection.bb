SUMMARY = "RTC detection"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://rtc-detection.sh \
           "

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        rtc-detection.service \
        "

do_install(){
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/rtc-detection.sh ${D}/${bindir}/
}
