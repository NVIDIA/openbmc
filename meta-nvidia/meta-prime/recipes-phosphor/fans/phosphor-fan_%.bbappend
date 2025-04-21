SRC_URI = "git://github.com/NVIDIA/phosphor-fan-presence;protocol=https;branch=develop"
SRCREV = "7d07cb1ef3c2347e6355aabfa7e8a48bfdac6dbf"

PACKAGECONFIG:remove = "control presence monitor"

SYSTEMD_SERVICE:${PN}-control:remove = "phosphor-fan-control@.service"
SYSTEMD_SERVICE:${PN}-control:remove = "phosphor-fan-control-init@.service"
SYSTEMD_SERVICE:${PN}-presence-tach:remove = "phosphor-fan-presence-tach@.service"
SYSTEMD_SERVICE:${PN}-monitor:remove = "phosphor-fan-monitor@.service"
SYSTEMD_SERVICE:${PN}-monitor:remove = "phosphor-fan-monitor-init@.service"
