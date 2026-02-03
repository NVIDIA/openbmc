FILESEXTRAPATHS:append := "${THISDIR}/config:"

SRC_URI:append = " \
           file://phosphor-logging-namespace.json \
           "

do_install:append() {
    install -d ${D}${sysconfdir}/phosphor-logging/conf
    install -m 0644 ${UNPACKDIR}/phosphor-logging-namespace.json ${D}${sysconfdir}/phosphor-logging/conf
}
