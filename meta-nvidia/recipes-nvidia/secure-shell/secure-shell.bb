SUMMARY = "Initial secure shell configuration script"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

S = "${WORKDIR}"

SRC_URI = " \
        file://rbash \
        file://secure-shell.sh \
        file://secure-shell.service \
        file://secure-shell-debug-token-root-enable.sh \
"

SYSTEMD_SERVICE:${PN} = "secure-shell.service"

LOCAL_BIN_DIR = "/usr/local/bin/nvidia"

FILES:${PN} += " \
    ${bindir}/rbash \
    ${bindir}/secure-shell.sh \
    ${bindir}/secure-shell-debug-token-root-enable.sh \
    ${systemd_system_unitdir}/secure-shell.service \
    ${systemd_system_unitdir}/multi-user.target.wants/secure-shell.service \
    ${LOCAL_BIN_DIR}/scp \
    "

do_install() {
    install -d ${D}${bindir}
    install -m 755 ${S}/secure-shell.sh ${D}${bindir}/
    install -m 755 ${S}/secure-shell-debug-token-root-enable.sh ${D}${bindir}/
    install -m 755 ${S}/rbash ${D}${bindir}/

    install -d ${D}${systemd_system_unitdir}
    install -m 644 ${S}/secure-shell.service ${D}${systemd_system_unitdir}/

    install -d ${D}${systemd_system_unitdir}/multi-user.target.wants
    ln -s -r ${D}${systemd_system_unitdir}/secure-shell.service ${D}${systemd_system_unitdir}/multi-user.target.wants/secure-shell.service

    install -d ${D}${LOCAL_BIN_DIR}
    ln -s -r ${D}${bindir}/scp ${D}${LOCAL_BIN_DIR}/scp
}
