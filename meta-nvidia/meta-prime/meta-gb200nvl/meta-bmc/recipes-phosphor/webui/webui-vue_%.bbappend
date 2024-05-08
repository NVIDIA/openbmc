FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "git://github.com/NVIDIA/webui-vue;protocol=https;branch=develop \
           file://0001-Patch-webui-vue-to-match-the-BMC-s-Redfish-URIs.patch \
           file://0001-upstream_sync-Fix-eslint-npm-error.patch \
           "
SRCREV = "5435191c636b03afde72bc1b574aca0e1a499ec4"
