SUMMARY = "Switchtec User utility"
DESCRIPTION = "Compile switchtec-user for OpenBMC"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3d6b07c89629cff2990d2e8e1f4c2382"

SRC_URI = "git://github.com/Microsemi/switchtec-user.git;branch=master;protocol=https"
SRCREV = "1c0ced0af7b35df185d0ef2c61f3671d0b6cf16b"

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
