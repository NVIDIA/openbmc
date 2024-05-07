FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI += "file://reserved-list"

do_install:append() {
    install -m 0644 ${WORKDIR}/reserved-list ${D}/reserved-list
}

FILES:${PN} += " /reserved-list"
