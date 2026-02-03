SUMMARY = "RTC detection"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit obmc-phosphor-systemd
RDEPENDS:${PN} = "bash"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = "file://rtc-detection.sh"

SYSTEMD_PACKAGES = "${PN}"

do_install(){
    install -d ${D}/${bindir}
    install -m 0755 ${UNPACKDIR}/rtc-detection.sh ${D}/${bindir}/
}
