FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', "file://username-obmchost.patch", '', d)} \
           "
