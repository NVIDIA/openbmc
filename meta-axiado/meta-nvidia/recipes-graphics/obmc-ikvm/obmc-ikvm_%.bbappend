FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Description for this patch 
# http://sourcevault.axiadord:7990/projects/ON/repos/meta-axiado/pull-requests/41/overview?commentId=778225
SRC_URI:append:gb200nvl-bmc-axiado = " file://0001-obmc-ikvm-link-udc-mt-nvidia.patch"
SRC_URI:append:gb300nvl-bmc-axiado = " file://0001-obmc-ikvm-link-udc-mt-nvidia.patch"
SRC_URI:append:gb200nvl-bmc-axiado-github = " file://0001-obmc-ikvm-link-udc-mt-nvidia-github.patch"

#FIXME: KWS-6639
# SRC_URI += "file://0002-KWS-6639-Dbus-Support-for-Screen-Capture.patch"
