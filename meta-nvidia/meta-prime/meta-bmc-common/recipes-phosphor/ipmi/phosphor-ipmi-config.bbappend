FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://dev_id.json "

do_install:append() {
    install -m 0644 -D ${WORKDIR}/dev_id.json \
        ${D}${datadir}/ipmi-providers/dev_id.json
}
