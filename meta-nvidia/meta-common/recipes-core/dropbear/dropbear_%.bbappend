FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}/${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', 'secure-shell', 'non-secure-shell', d)}:"
SRC_URI += "file://password-change-client.patch \
            file://password-change-server.patch \
            ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', "file://default_options.patch", '', d)} \
            ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', "file://scp-path-restriction.patch", '', d)} \
           "

RDEPENDS:${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', 'pam-plugin-exec', '', d)}"
