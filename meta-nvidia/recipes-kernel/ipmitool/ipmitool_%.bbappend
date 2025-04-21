FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

IANA_ENTERPRISE_NUMBERS = "file://iana-enterprise-numbers"

SRCREV = "eb1df8d6a608074c05a1db768830747c01927aaa"
SRC_URI = " git://github.com/NVIDIA/codeberg-ipmitool;protocol=https;branch=develop;name=override; \
           ${IANA_ENTERPRISE_NUMBERS} \
           file://0001-csv-revision-Drop-the-git-revision-info.patch \
           "
