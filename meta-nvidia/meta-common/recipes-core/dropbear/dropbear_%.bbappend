FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://password-change-client.patch \
            file://password-change-server.patch \
            ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', "file://default_options.patch", '', d)} \
            ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', "file://scp-path-restriction.patch", '', d)} \
            ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', "file://pam.d/dropbear-secure-shell", 'file://pam.d/dropbear-non-secure-shell', d)} \
            ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell-debug-token-login-enable', "file://pam.d/dropbear-secure-shell-debug-token-login-enable", '', d)} \
           "

RDEPENDS:${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', 'pam-plugin-exec', '', d)}"

do_install:append() {
    rm -f ${D}${sysconfdir}/pam.d/dropbear
    install -d ${D}${sysconfdir}/pam.d

    SECURESHELLROOT=${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell-debug-token-login-enable', '1', '0', d)}
    SECURESHELL=${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', '1', '0', d)}
    if [ "${SECURESHELLROOT}" = "1" -a "${SECURESHELL}" = "0" ]; then
        bbfatal "nvidia-secure-shell-debug-token-login-enable is added to DISTRO_FEATURES, but nvidia-secure-shell is not"
    elif [ "${SECURESHELLROOT}" = "1" ]; then
        install -m 0644 ${WORKDIR}/pam.d/dropbear-secure-shell-debug-token-login-enable ${D}${sysconfdir}/pam.d/dropbear
        sed -i "s/-G priv-admin[ ]*//g" ${D}${sysconfdir}/default/dropbear
    elif [ "${SECURESHELL}" = "1" ]; then
        install -m 0644 ${WORKDIR}/pam.d/dropbear-secure-shell ${D}${sysconfdir}/pam.d/dropbear
        sed -i "s/-G priv-admin[ ]*//g" ${D}${sysconfdir}/default/dropbear
    else
        install -m 0644 ${WORKDIR}/pam.d/dropbear-non-secure-shell ${D}${sysconfdir}/pam.d/dropbear
    fi
}
