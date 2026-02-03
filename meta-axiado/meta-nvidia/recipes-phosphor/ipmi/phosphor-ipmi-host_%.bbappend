FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# AXGIGABYTE-17
SRC_URI:append += "file://0001-Reuse-DHCP-IP-when-transitioning-to-Static-IP.patch"
