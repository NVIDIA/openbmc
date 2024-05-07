SUMMARY = "Set BMC time to HMC at boot time"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://set-hmc-time.sh \
           "

RTC_READY_SCRIPT = "set-hmc-time.sh"

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        set-hmc-time.service \
        set-hmc-time.timer \
        "

do_install(){
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/${RTC_READY_SCRIPT} ${D}/${bindir}/set-hmc-time.sh
}

