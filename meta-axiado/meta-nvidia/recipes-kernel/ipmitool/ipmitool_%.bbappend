FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

IANA_ENTERPRISE_NUMBERS = "file://iana-enterprise-numbers"
#FIXME : Nvidia did not opensource their ipmitool repo yet
SRCREV = "ab5ce5baff097ebb6e2a17a171858be213ee68d3"
SRC_URI = "git://codeberg.org/ipmitool/ipmitool;protocol=https;branch=master \
           ${IANA_ENTERPRISE_NUMBERS} \
           file://0001-csv-revision-Drop-the-git-revision-info.patch \
           "
