FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:${THISDIR}/csm:"

SRC_URI:append = " file://MctpReady.json \
                   file://poweron-log.conf \
                 "

SYSTEMD_SERVICE:${PN}-chassis:remove = "obmc-power-start@.service"
SYSTEMD_SERVICE:${PN}-chassis:remove = "obmc-power-stop@.service"
SYSTEMD_SERVICE:${PN}-chassis:remove = "phosphor-reset-chassis-on@.service"
SYSTEMD_SERVICE:${PN}-chassis:remove = "phosphor-reset-chassis-running@.service"

FILES:${PN}:remove = " \
    ${base_libdir}/systemd/system/obmc-power-start@.service \
    ${base_libdir}/systemd/system/obmc-power-stop@.service \
    ${base_libdir}/systemd/system/phosphor-reset-chassis-on@.service \
    ${base_libdir}/systemd/system/phosphor-reset-chassis-running@.service \
"

FILES:${PN}-csm:append= " ${datadir}/configurable-state-manager/MctpReady.json "

FILES:${PN}-chassis-poweron-log:append = " ${systemd_system_unitdir}/phosphor-create-chassis-poweron-log@.service.d/poweron-log.conf ${systemd_system_unitdir}/phosphor-create-chassis-poweron-log@.service.d"
SYSTEMD_OVERRIDE:${PN}-chassis-poweron-log += "poweron-log.conf:phosphor-create-chassis-poweron-log@.service.d/poweron-log.conf"

do_install:append() {
        install -m 0644 ${UNPACKDIR}/MctpReady.json ${D}${datadir}/configurable-state-manager/

        # Remove chassis power service files that create mapper-wait dependencies
        rm -f ${D}${base_libdir}/systemd/system/obmc-power-start@.service
        rm -f ${D}${base_libdir}/systemd/system/obmc-power-stop@.service
        rm -f ${D}${base_libdir}/systemd/system/phosphor-reset-chassis-on@.service
        rm -f ${D}${base_libdir}/systemd/system/phosphor-reset-chassis-running@.service

    install -d ${D}${systemd_system_unitdir}/phosphor-create-chassis-poweron-log@.service.d
    install -m 0644 ${UNPACKDIR}/poweron-log.conf ${D}${systemd_system_unitdir}/phosphor-create-chassis-poweron-log@.service.d/
}
