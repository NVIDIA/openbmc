FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# AXBUGS-1842
SRC_URI += "file://0001-AXBUGS-1842-Update-Bootprogress-for-warm-reset.patch"
