FILESEXTRAPATHS:append := "${THISDIR}/config:"

SRC_URI:append = " \
           file://phosphor-logging-namespace.json \
           "
EXTRA_OEMESON:append = " -Dnvbmc-logging-extension=enabled"

do_install:append() {
    install -d ${D}${sysconfdir}/phosphor-logging/conf
    install -m 0644 ${WORKDIR}/phosphor-logging-namespace.json ${D}${sysconfdir}/phosphor-logging/conf
}
