FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-user-manager;protocol=https;branch=develop"
SRC_URI += "file://upgrade_hostconsole_group.sh"
SRCREV = "8e318d195a9eedd35a357c3253aac5e73070791d"

DEPENDS += "libpwquality"
DEPENDS += "libpam"

def get_oeconf(d, filename, policy_var, search_key):
    import re
    import os

    folder_path = d.expand("${TOPDIR}/password-policy")
    full_path = os.path.join(folder_path, filename) 
    if not os.path.exists(full_path):
        bb.warn(f"Config file NOT found: {full_path}")
        return ""
    rval = ""

    try:
        with open(full_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    match = re.match(rf'^{search_key}\s*=\s*(\S+)', line)
                    if match:
                        search_result = match.group(1)
                        rval = " -D" + policy_var;
                        rval += "="
                        rval += search_result
                        #bb.warn(f"Found value for {rval}: {rval}")
                        break
            else:
                bb.warn(f"{search_key} not found in config file")

    except Exception as e:
        bb.error(f"Error reading config file: {str(e)}")

    return rval
EXTRA_OEMESON += "${@get_oeconf(d, 'pwquality.conf', 'MIN_PASSWORD_LENGTH', 'minlen')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'faillock.conf', 'ACCOUNT_UNLOCK_TIMEOUT', 'unlock_time')}"
EXTRA_OEMESON += "${@get_oeconf(d, 'faillock.conf', 'MAX_FAILED_LOGIN_ATTEMPTS', 'deny')}"
