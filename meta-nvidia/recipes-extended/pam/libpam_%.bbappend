FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " file://pam.d/common-auth"
SRC_URI += " file://convert-pam-configs.sh"

do_install:append() {
  if [ -e "${WORKDIR}/faillock.conf" ]; then
    install -d ${TOPDIR}/password-policy
    install -m 0644 ${WORKDIR}/faillock.conf ${TOPDIR}/password-policy/faillock.conf
  fi
}
