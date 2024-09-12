
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"


SRC_URI:append += " \
                  file://cleanup_vme.sh \
                  file://setup_vme.sh \
"

do_install:append() {
	install -m 0755 ${WORKDIR}/cleanup_vme.sh ${D}${bindir}/
	install -m 0755 ${WORKDIR}/setup_vme.sh ${D}${bindir}/
}
