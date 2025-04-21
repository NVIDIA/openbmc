FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://defaults.override.yml \
                   file://logging-settings.override.yml \
                 "
