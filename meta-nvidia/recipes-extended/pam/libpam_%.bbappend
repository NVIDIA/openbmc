FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " file://pam.d/common-auth"
SRC_URI += " file://convert-pam-configs.sh"

do_install:append() {
  if [ -e "${UNPACKDIR}/faillock.conf" ]; then
    install -d ${TOPDIR}/password-policy
    install -m 0644 ${UNPACKDIR}/faillock.conf ${TOPDIR}/password-policy/faillock.conf
  fi
}
