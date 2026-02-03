PACKAGECONFIG:append = " json sensor-monitor"
PACKAGECONFIG[sensor-monitor] = "\
			-Duse-host-power-state=enabled \
			-Dsensor-monitor-persist-root-path=/var/lib/sensor-monitor \
			-Dsensor-monitor-soft-shutdown-delay=60000 \
			-Dsensor-monitor-hard-shutdown-delay=3000 \
			-Dsensor-monitor-enable-threshold-alarm-logger=disabled"
