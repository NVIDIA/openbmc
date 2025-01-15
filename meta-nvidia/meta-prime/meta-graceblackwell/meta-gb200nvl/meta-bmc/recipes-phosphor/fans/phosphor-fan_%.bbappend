FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI += "file://0001-catch-std-exception-and-add-soft-shutdown-graceful-s.patch"

PACKAGECONFIG:append = " json sensor-monitor"
PACKAGECONFIG[sensor-monitor] = "\
			-Duse-host-power-state=enabled \
			-Dsensor-monitor-persist-root-path=/var/lib/sensor-monitor \
			-Dsensor-monitor-soft-shutdown-delay=60000 \
			-Dsensor-monitor-hard-shutdown-delay=1000"
