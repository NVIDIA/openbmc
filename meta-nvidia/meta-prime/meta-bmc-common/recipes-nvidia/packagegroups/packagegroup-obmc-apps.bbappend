#
# Remove phosphor-health-monitor
#
#RDEPENDS:${PN}-fan-control:append = "sensor-monitor"
RDEPENDS:${PN}-health-monitor:remove = "phosphor-health-monitor"