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
     if [ -e "${WORKDIR}/pwquality.conf" ]; then
        install -d ${TOPDIR}/password-policy
        install -m 0644 ${WORKDIR}/pwquality.conf ${TOPDIR}/password-policy/pwquality.conf
    fi

    install -d ${D}/etc/security
    install -m 0644 ${WORKDIR}/pwquality.conf ${D}/etc/security

    if [ "${UPDATE_CONDITIONAL}" = "1" ] && [ "${UPDATE_UNIVERSAL}" = "1" ]; then
        bbfatal "Only one password policy update method can be selected"
    fi
    if [ "${UPDATE_CONDITIONAL}" = "1" ] || [ "${UPDATE_UNIVERSAL}" = "1" ]; then
        mv ${D}/etc/security/pwquality.conf ${D}/etc/security/pwquality.conf-defaults
    fi
    if [ "${UPDATE_CONDITIONAL}" = "1" ] && [ ! -z "${PREVIOUS_DEFAULTS}" ]; then
        install -d ${D}/etc/security/pwquality.conf.d
        for f in "${PREVIOUS_DEFAULTS}"; do
            TRIMMED_PATH=$(echo "${f}" | xargs)
            install -m 0644 ${WORKDIR}/${TRIMMED_PATH} ${D}/etc/security/pwquality.conf.d
        done
    fi
}
