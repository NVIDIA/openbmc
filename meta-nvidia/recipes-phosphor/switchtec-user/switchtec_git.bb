SUMMARY = "Switchtec User utility"
DESCRIPTION = "Compile switchtec-user for OpenBMC"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3d6b07c89629cff2990d2e8e1f4c2382"

SRC_URI = "git://github.com/Microsemi/switchtec-user.git;branch=master;protocol=https"
SRCREV = "729948a6d19c2726ce14103b9e66c02926e23d05"

S = "${WORKDIR}/git"

do_configure[cleandirs] += "${B}"

inherit autotools

DEPENDS += "autoconf-archive openssl"
EXTRA_OECONF = "--with-openssl"


do_configure:prepend () {
	cd ${S}
}

do_compile:prepend (){
	cd ${S}
}

do_install () {
	cd ${S}
	install -d ${D}/${bindir}
	install -m 0755 ${S}/switchtec ${D}/${bindir}
}
