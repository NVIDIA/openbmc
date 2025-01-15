#
# Remove phosphor-health-monitor
#
RDEPENDS:${PN}-fan-control:append = " phosphor-fan-sensor-monitor "
RDEPENDS:${PN}-health-monitor:remove = "phosphor-health-monitor"