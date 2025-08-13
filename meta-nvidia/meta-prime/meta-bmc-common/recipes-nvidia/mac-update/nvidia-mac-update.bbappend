FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://fru.conf"

FRU_CONF = "fru.conf"

do_install:append() {
    install -d ${D}/${bindir}
    install -d ${D}/etc/default/
    install -m 0755 ${UNPACKDIR}/nvidia_update_mac.sh ${D}/${bindir}/
    install -m 0755 ${UNPACKDIR}/${FRU_CONF} ${D}/etc/default/fru.conf
}

