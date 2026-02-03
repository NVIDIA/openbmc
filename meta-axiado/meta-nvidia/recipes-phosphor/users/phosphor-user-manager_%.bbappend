FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# AXBUGS-1710
SRC_URI += "file://0001-ipmitool-redfish-user-disable-1-command-should-not-a.patch"
# AXBUGS-1718
SRC_URI += "file://0001-AXBUGS-1718-Prevent-login-for-users-without-LDAP-Rol.patch"
