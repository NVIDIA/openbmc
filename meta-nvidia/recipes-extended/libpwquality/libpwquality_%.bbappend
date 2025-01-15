FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
        file://pwquality.conf \
        "

do_install:append() {
  if [ -e "${WORKDIR}/pwquality.conf" ]; then
    install -d ${TOPDIR}/password-policy
    install -m 0644 ${WORKDIR}/pwquality.conf ${TOPDIR}/password-policy/pwquality.conf
  fi
}
