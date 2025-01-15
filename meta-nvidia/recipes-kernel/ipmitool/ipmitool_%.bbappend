FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

IANA_ENTERPRISE_NUMBERS = "file://iana-enterprise-numbers"

SRCREV = "03ea765618d68ee03d7b4642d80205cf8fa55cc2"
SRC_URI = " git://github.com/NVIDIA/codeberg-ipmitool;protocol=https;branch=develop;name=override; \
           ${IANA_ENTERPRISE_NUMBERS} \
           file://0001-csv-revision-Drop-the-git-revision-info.patch \
           "
