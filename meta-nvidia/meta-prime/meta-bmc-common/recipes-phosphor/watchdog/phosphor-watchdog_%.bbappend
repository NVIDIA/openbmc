FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"
SRCREV = "fcc00392e8f70c2fc8f911595629869e2f6c6cfb"
# Remove the override to keep service running after DC cycle
SYSTEMD_OVERRIDE_${PN}:remove = "poweron.conf:phosphor-watchdog@poweron.service.d/poweron.conf"
SYSTEMD_SERVICE:${PN} = "phosphor-watchdog.service phosphor-watchdog-host-poweroff.service phosphor-watchdog-host-reset.service phosphor-watchdog-host-cycle.service"
