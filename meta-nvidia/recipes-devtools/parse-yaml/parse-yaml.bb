SUMMARY = "A simple yaml parser implemented in bash."

PV = "0.1"

SRC_URI += "git://github.com/mrbaseman/parse_yaml;name=parse_yaml;protocol=https;branch=master"
SRCREV = "c0349563865c80423bcdcd576ce515008c928fc3"

LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${WORKDIR}/git/LICENSE;md5=d32239bcb673463ab874e80d47fae504"

RDEPENDS:${PN} += "bash gawk"

S = "${WORKDIR}"

do_install() {
	install -d ${D}/usr/bin
	install -m 0755 ${WORKDIR}/git/src/parse_yaml.sh ${D}/usr/bin/
}

FILES:${PN} += "/usr/bin/parse_yaml.sh"
