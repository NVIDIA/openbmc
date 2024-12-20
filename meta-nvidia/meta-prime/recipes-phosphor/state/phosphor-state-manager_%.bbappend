FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:${THISDIR}/csm:"

SRC_URI = "git://github.com/NVIDIA/phosphor-state-manager;protocol=https;branch=develop"
SRCREV = "f006cce7d9902f9c062188608306a6e8536fa8f7"

SRC_URI:append = " \
           file://phosphor-clear-one-time@.service \
           file://phosphor-reset-host-reboot-attempts@.service \
           file://phosphor-reset-host-recovery@.service \
           file://phosphor-reset-sensor-states@.service \
           file://phosphor-set-host-transition-to-off@.service \
           file://phosphor-set-host-transition-to-running@.service \
           "

SRC_URI:append = " \
           file://xyz.openbmc_project.State.ConfigurableStateManager.service \
           file://TelemetryReady.json \
           "

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS += "systemd"
DEPENDS += "bash"
PACKAGECONFIG:remove = " no-warm-reboot"
EXTRA_OEMESON += "-Dhost-gpios=disabled"

SYSTEMD_PACKAGES:append = " ${PN}-csm"
STATE_MGR_PACKAGES:append = " ${PN}-csm"
SYSTEMD_SERVICE:${PN}-csm = " xyz.openbmc_project.State.ConfigurableStateManager.service"

pkg_postinst:${PN}-obmc-targets:append() {
        rm $D$systemd_system_unitdir/obmc-host-force-warm-reboot@0.target.requires/obmc-host-stop@0.target
        rm $D$systemd_system_unitdir/obmc-host-force-warm-reboot@0.target.requires/phosphor-reboot-host@0.service
        rm $D$systemd_system_unitdir/obmc-host-warm-reboot@0.target.requires/xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service
        rm $D$systemd_system_unitdir/obmc-host-warm-reboot@0.target.requires/obmc-host-force-warm-reboot@0.target
}


do_install:append() {
        install -d ${D}${base_libdir}/systemd/system
        install -m 0644 ${WORKDIR}/phosphor-clear-one-time@.service ${D}${base_libdir}/systemd/system/phosphor-clear-one-time@.service
        install -m 0644 ${WORKDIR}/phosphor-reset-host-reboot-attempts@.service ${D}${base_libdir}/systemd/system/phosphor-reset-host-reboot-attempts@.service
        install -m 0644 ${WORKDIR}/phosphor-reset-host-recovery@.service ${D}${base_libdir}/systemd/system/phosphor-reset-host-recovery@.service
        install -m 0644 ${WORKDIR}/phosphor-reset-sensor-states@.service ${D}${base_libdir}/systemd/system/phosphor-reset-sensor-states@.service
        install -m 0644 ${WORKDIR}/phosphor-set-host-transition-to-off@.service ${D}${base_libdir}/systemd/system/phosphor-set-host-transition-to-off@.service
        install -m 0644 ${WORKDIR}/phosphor-set-host-transition-to-running@.service ${D}${base_libdir}/systemd/system/phosphor-set-host-transition-to-running@.service

        # install CSM
        install -d ${D}${base_libdir}/systemd/system
        install -m 0644 ${WORKDIR}/xyz.openbmc_project.State.ConfigurableStateManager.service ${D}${base_libdir}/systemd/system/
        install -d ${D}${datadir}/configurable-state-manager
        install -m 0644 ${WORKDIR}/TelemetryReady.json ${D}${datadir}/configurable-state-manager/
}

FILES:${PN}-csm:append= " ${base_libdir}/systemd/system/xyz.openbmc_project.State.ConfigurableStateManager.service \
                          ${bindir}/configurable-state-manager \
                          ${datadir}/configurable-state-manager/TelemetryReady.json \
                        "

FILES:${PN}:append= " \
         ${base_libdir}/systemd/system/phosphor-clear-one-time@.service \
         ${base_libdir}/systemd/system/phosphor-reset-host-reboot-attempts@.service \
         ${base_libdir}/systemd/system/phosphor-reset-host-recovery@.service \
         ${base_libdir}/systemd/system/phosphor-reset-sensor-states@.service \
         ${base_libdir}/systemd/system/phosphor-set-host-transition-to-off@.service \
         ${base_libdir}/systemd/system/phosphor-set-host-transition-to-running@.service \
         ${base_libdir}/systemd/system/phosphor-reset-chassis-running@.service \
         ${base_libdir}/systemd/system/obmc-powered-off@.service \
         ${base_libdir}/systemd/system/obmc-power-stop@.service \
         ${base_libdir}/systemd/system/obmc-chassis-powercycle@.target \
         ${base_libdir}/systemd/system/phosphor-set-chassis-transition-to-off@.service \
         ${base_libdir}/systemd/system/obmc-power-start@.service \
         ${base_libdir}/systemd/system/phosphor-reset-chassis-on@.service \
         ${base_libdir}/systemd/system/phosphor-set-chassis-transition-to-on@.service \
        "
