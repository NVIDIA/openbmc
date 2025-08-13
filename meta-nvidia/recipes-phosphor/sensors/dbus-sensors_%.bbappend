PACKAGECONFIG[mctpreactor] = "-Dmctp=enabled, -Dmctp=disabled"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'mctpreactor', \
                                               'xyz.openbmc_project.mctpreactor.service', \
                                               '', d)}"

PACKAGECONFIG[mctpheartbeat] = "-Dmctpheartbeat=enabled, -Dmctpheartbeat=disabled"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'mctpheartbeat', 'xyz.openbmc_project.mctpheartbeatapp.service', '', d)}"