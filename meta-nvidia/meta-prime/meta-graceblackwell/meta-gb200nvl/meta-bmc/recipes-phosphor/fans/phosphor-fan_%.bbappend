FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI += "file://0001-catch-std-exception-and-add-soft-shutdown-graceful-s.patch"

SYSTEMD_SERVICE:${PN}-control:remove = "phosphor-fan-control@.service"
SYSTEMD_SERVICE:${PN}-presence-tach:remove = "phosphor-fan-presence-tach@.service"
SYSTEMD_SERVICE:${PN}-monitor:remove = "phosphor-fan-monitor@.service"

PACKAGECONFIG:append = " json sensor-monitor"
PACKAGECONFIG:remove = "control presence monitor"
PACKAGECONFIG[sensor-monitor] = "\
			-Duse-host-power-state=enabled \
			-Dsensor-monitor-persist-root-path=/var/lib/sensor-monitor \
			-Dsensor-monitor-soft-shutdown-delay=60000 \
			-Dsensor-monitor-hard-shutdown-delay=2000"
