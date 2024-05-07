FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " file://pam.d/common-auth"
SRC_URI += " file://convert-pam-configs.sh"
