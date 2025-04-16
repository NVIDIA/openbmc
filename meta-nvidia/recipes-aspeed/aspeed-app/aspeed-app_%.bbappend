
FILES:${PN}:remove = " /usr/bin/mctp "

do_install:append() {
    rm -f ${D}${bindir}/mctp
}