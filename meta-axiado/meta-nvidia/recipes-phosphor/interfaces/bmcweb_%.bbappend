FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# AXBUGS-1713
SRC_URI += "file://0001-AXBUGS-1713-1763-1814-removed-irregularities-in-role.patch"

#FIXME
#SRC_URI += "file://0001-KWS-6639-RedfishSupportForScreenCapture.patch \
#            file://0001-NvidiaManager-v1-xml.patch

CXX += "-Wno-error=free-nonheap-object"
