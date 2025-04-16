FILES:${PN} += " \
    ${LOCAL_BIN_DIR}/ssh \
    "

do_install:append() {
    ln -s -r ${D}${bindir}/ssh ${D}${LOCAL_BIN_DIR}/ssh
}
