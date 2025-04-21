FILESEXTRAPATHS:prepend := "${THISDIR}/csm:"

SRC_URI:append = " file://TelemetryReady.json \
                   file://MctpReady.json \
                   file://xyz.openbmc_project.State.ConfigurableStateManager.service \
                 "


FILES:${PN}-csm:append= " ${datadir}/configurable-state-manager/MctpReady.json "

do_install:append() {
        install -m 0644 ${WORKDIR}/MctpReady.json ${D}${datadir}/configurable-state-manager/
}
