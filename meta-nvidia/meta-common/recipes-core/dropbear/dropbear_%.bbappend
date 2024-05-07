FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://password-change-client.patch \
            file://password-change-server.patch \
            ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', "file://default_options.patch", '', d)} \
            ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', "file://username.patch", '', d)} \
            file://dropbear \
           "
