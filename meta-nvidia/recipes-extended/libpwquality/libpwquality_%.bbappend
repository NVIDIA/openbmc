FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
        file://pwquality.conf \
        file://previous-defaults/pwquality-1.conf \
        "

PREVIOUS_DEFAULTS = " \
    previous-defaults/pwquality-1.conf \
    "

UPDATE_CONDITIONAL = "${@bb.utils.contains('DISTRO_FEATURES', 'password-policy-update-conditional', '1', '0', d)}"
UPDATE_UNIVERSAL = "${@bb.utils.contains('DISTRO_FEATURES', 'password-policy-update-universal', '1', '0', d)}"

do_install:append() {
  if [ -e "${UNPACKDIR}/pwquality.conf" ]; then
    install -d ${TOPDIR}/password-policy
    install -m 0644 ${UNPACKDIR}/pwquality.conf ${TOPDIR}/password-policy/pwquality.conf
  fi
}
