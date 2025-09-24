FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://mapper-subtree-remove.conf "

FILES:${PN}:append = " ${systemd_system_unitdir}/mapper-subtree-remove@.service.d/mapper-subtree-remove.conf ${systemd_system_unitdir}/mapper-subtree-remove@.service.d "
SYSTEMD_OVERRIDE:${PN} += "mapper-subtree-remove.conf:mapper-subtree-remove@.service.d/mapper-subtree-remove.conf"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}/mapper-subtree-remove@.service.d
    install -m 0644 ${UNPACKDIR}/mapper-subtree-remove.conf ${D}${systemd_system_unitdir}/mapper-subtree-remove@.service.d/
}
