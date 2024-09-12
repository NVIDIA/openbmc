FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
           file://0001-enable-service-execution-on-startup.patch \
           "
SRCREV = "8377d59c61c653a34df1c3c4ca72219eceb0b43b"
