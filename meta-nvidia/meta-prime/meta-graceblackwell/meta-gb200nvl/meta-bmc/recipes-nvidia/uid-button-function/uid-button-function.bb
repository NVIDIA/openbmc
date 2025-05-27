SUMMARY = "Monitor UID button Signals"
PR = "r1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "git://github.com/NVIDIA/uid-button-function;protocol=https;branch=main"
SRCREV = "2a7ab9a239a3a4d97218049a863c1bef9d1c5ee1"

PV = "1.0+git${SRCPV}"

inherit meson systemd pkgconfig obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI += " \
           file://passwordreset \
           "
EXTRA_OEMESON = "-Dusername=root -Dpassword=0penBmc"

DEPENDS = " \
           systemd \
           sdbusplus \
           phosphor-logging \
           libpam \
"
RDEPENDS:${PN} = "bash "

SYSTEMD_SERVICE:${PN} = " \
        uid-button-function.service \
        "

S = "${WORKDIR}/git"

do_install(){
    install -d ${D}/${bindir}
    install -m 0755 uid-button-function ${D}/${bindir}/uid-button-function
    install -d ${D}/${sysconfdir}/pam.d
    install -m 0755 ${WORKDIR}/passwordreset ${D}/${sysconfdir}/pam.d/passwordreset
}
FILES_${PN} += "${sysconfdir}/pam.d/passwordreset"

