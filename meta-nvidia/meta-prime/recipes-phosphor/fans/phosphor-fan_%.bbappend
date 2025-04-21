SRC_URI = "git://github.com/NVIDIA/phosphor-fan-presence;protocol=https;branch=develop"
SRCREV = "72fb5c2bbad2d319a279a263e49723151d60c6ba"

PACKAGECONFIG:remove = "control presence monitor"

SYSTEMD_SERVICE:${PN}-control:remove = "phosphor-fan-control@.service"
SYSTEMD_SERVICE:${PN}-control:remove = "phosphor-fan-control-init@.service"
SYSTEMD_SERVICE:${PN}-presence-tach:remove = "phosphor-fan-presence-tach@.service"
SYSTEMD_SERVICE:${PN}-monitor:remove = "phosphor-fan-monitor@.service"
SYSTEMD_SERVICE:${PN}-monitor:remove = "phosphor-fan-monitor-init@.service"
