SRC_URI = "git://github.com/NVIDIA/phosphor-fan-presence;protocol=https;branch=develop"
SRCREV = "f540aba3c1bb2ac62c570fb1fe1bbea9f616221f"

PACKAGECONFIG:remove = "control presence monitor"

SYSTEMD_SERVICE:${PN}-control:remove = "phosphor-fan-control@.service"
SYSTEMD_SERVICE:${PN}-control:remove = "phosphor-fan-control-init@.service"
SYSTEMD_SERVICE:${PN}-presence-tach:remove = "phosphor-fan-presence-tach@.service"
SYSTEMD_SERVICE:${PN}-monitor:remove = "phosphor-fan-monitor@.service"
SYSTEMD_SERVICE:${PN}-monitor:remove = "phosphor-fan-monitor-init@.service"
