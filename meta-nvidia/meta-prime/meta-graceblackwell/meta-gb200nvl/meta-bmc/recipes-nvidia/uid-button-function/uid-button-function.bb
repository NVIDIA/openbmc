SUMMARY = "Monitor UID button Signals"
PR = "r1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "git://github.com/NVIDIA/uid-button-function;protocol=https;branch=main"
SRCREV = "ea708e320e6001819a510fb23da1a67ecc18aafb"

PV = "1.0+git${SRCPV}"

inherit meson systemd pkgconfig obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI += " \
           file://passwordreset \
           "

# Default credentials for the password reset function
EXTRA_OEMESON:append = "${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-admin-account', ' -Dusername=admin -Dpassword=admin', ' -Dusername=root -Dpassword=0penBmc', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('BUILD_TYPE', 'prod', ' -Dexpire_password=true', '', d)}"

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

