FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-user-manager;protocol=https;branch=develop"
SRC_URI += "file://upgrade_hostconsole_group.sh"
SRCREV = "e5937977a6afe50761bfb49407ef2236c0911d0f"

def get_oeconf(d, policy_var, meson_var):
    val = d.getVar(policy_var , True)
    if val is None:
        return ""
    if not val:
        return ""
    rval = " -D" + policy_var;
    rval += "="
    rval += val
    return rval

EXTRA_OEMESON += "${@get_oeconf(d, 'MIN_UCASE_CHRS', 'min-ucase-characters')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'MIN_LCASE_CHRS', 'min-lcase-characters')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'MIN_DIGITS', 'min-digits')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'MIN_SPEC_CHRS', 'min-special-characters')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'MIN_PASSWORD_LENGTH', 'min-password-length')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'MAX_FAILED_LOGIN_ATTEMPTS', 'max-failed-login-attempts')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'ACCOUNT_UNLOCK_TIMEOUT', 'account-unlock-timeout')}"
