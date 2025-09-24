FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:${THISDIR}/csm:"

SRC_URI:append = " file://MctpReady.json \
                   file://poweron-log.conf \
                 "

FILES:${PN}-csm:append= " ${datadir}/configurable-state-manager/MctpReady.json "

FILES:${PN}-chassis-poweron-log:append = " ${systemd_system_unitdir}/phosphor-create-chassis-poweron-log@.service.d/poweron-log.conf ${systemd_system_unitdir}/phosphor-create-chassis-poweron-log@.service.d"
SYSTEMD_OVERRIDE:${PN}-chassis-poweron-log += "poweron-log.conf:phosphor-create-chassis-poweron-log@.service.d/poweron-log.conf"

do_install:append() {
    install -m 0644 ${UNPACKDIR}/MctpReady.json ${D}${datadir}/configurable-state-manager/

    install -d ${D}${systemd_system_unitdir}/phosphor-create-chassis-poweron-log@.service.d
    install -m 0644 ${UNPACKDIR}/poweron-log.conf ${D}${systemd_system_unitdir}/phosphor-create-chassis-poweron-log@.service.d/
}
