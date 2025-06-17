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
        file://hostconsole-login.sh \
        ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell-debug-token-login-enable', "file://secure-shell-debug-token-login-enable.sh", '', d)} \
"

SYSTEMD_SERVICE:${PN} = "secure-shell.service"

LOCAL_BIN_DIR = "/usr/local/bin/nvidia"

FILES:${PN} += " \
    ${bindir}/rbash \
    ${bindir}/secure-shell.sh \
    ${bindir}/secure-shell-debug-token-login-enable.sh \
    ${bindir}/hostconsole-login.sh \
    ${systemd_system_unitdir}/secure-shell.service \
    ${systemd_system_unitdir}/multi-user.target.wants/secure-shell.service \
    ${LOCAL_BIN_DIR}/scp \
    "

do_install() {
    SECURESHELLROOT=${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell-debug-token-login-enable', '1', '0', d)}
    SECURESHELL=${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', '1', '0', d)}
    if [ "${SECURESHELLROOT}" = "1" -a "${SECURESHELL}" = "0" ]; then
        bbfatal "nvidia-secure-shell-debug-token-login-enable is added to DISTRO_FEATURES, but nvidia-secure-shell is not"
    fi

    install -d ${D}${bindir}
    install -m 755 ${S}/secure-shell.sh ${D}${bindir}/
    install -m 755 ${S}/rbash ${D}${bindir}/
    install -m 755 ${S}/hostconsole-login.sh ${D}${bindir}/
    if [ "${SECURESHELLROOT}" = "1" ]; then
         install -m 755 ${S}/secure-shell-debug-token-login-enable.sh ${D}${bindir}/
    fi

    install -d ${D}${systemd_system_unitdir}
    install -m 644 ${S}/secure-shell.service ${D}${systemd_system_unitdir}/

    install -d ${D}${systemd_system_unitdir}/multi-user.target.wants
    ln -s -r ${D}${systemd_system_unitdir}/secure-shell.service ${D}${systemd_system_unitdir}/multi-user.target.wants/secure-shell.service

    install -d ${D}${LOCAL_BIN_DIR}
    ln -s -r ${D}${bindir}/scp ${D}${LOCAL_BIN_DIR}/scp
}
