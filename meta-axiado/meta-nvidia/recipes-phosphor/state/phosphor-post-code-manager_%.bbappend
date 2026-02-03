FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

# KWS-6654
SRC_URI += "file://0001-Ensure-post-code-manager-starts-after-lpcsnoop.patch"

