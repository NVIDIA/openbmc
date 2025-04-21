FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://defaults.override.yml \
                   file://TimeSync-default.override.yml \
                 "
