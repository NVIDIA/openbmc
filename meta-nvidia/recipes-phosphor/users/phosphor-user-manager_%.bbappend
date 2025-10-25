FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-user-manager;protocol=https;branch=develop"
SRC_URI += "file://upgrade_hostconsole_group.sh"
SRCREV = "bb6c81dbd72a242753f2823bec2f23fca04bb02a"

DEPENDS += "libpwquality"
DEPENDS += "libpam"

SRC_URI:append = " file://phosphor-user-manager-dropbearkey.conf"
FILES:${PN}:append = " ${systemd_system_unitdir}/xyz.openbmc_project.User.Manager.service.d/phosphor-user-manager-dropbearkey.conf"

SYSTEMD_OVERRIDE:${PN} += "phosphor-user-manager-dropbearkey.conf:xyz.openbmc_project.User.Manager.service.d/phosphor-user-manager-dropbearkey.conf"
do_install:append() {
    install -d ${D}${systemd_system_unitdir}/xyz.openbmc_project.User.Manager.service.d
    install -m 0644 ${UNPACKDIR}/phosphor-user-manager-dropbearkey.conf ${D}${systemd_system_unitdir}/xyz.openbmc_project.User.Manager.service.d/
}

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

PASSWORD_POLICY_UPDATE_ADOPTION_TYPE = "${@bb.utils.contains('DISTRO_FEATURES', 'password-policy-update-universal', 'universal', \
    "${@bb.utils.contains('DISTRO_FEATURES', 'password-policy-update-conditional', 'conditional', 'default', d)}", d)}"
EXTRA_OEMESON += "-DPOLICY_UPDATE_ADOPTION_TYPE=${PASSWORD_POLICY_UPDATE_ADOPTION_TYPE}"
