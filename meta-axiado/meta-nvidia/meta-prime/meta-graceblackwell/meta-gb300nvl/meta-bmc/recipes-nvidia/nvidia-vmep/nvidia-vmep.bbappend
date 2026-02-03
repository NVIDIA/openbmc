FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://cleanup_vme.sh \
            file://setup_vme.sh \
	    "

do_install:append() {
	install -m 0755 ${UNPACKDIR}/cleanup_vme.sh ${D}${bindir}/
	install -m 0755 ${UNPACKDIR}/setup_vme.sh ${D}${bindir}/
}
