#!/bin/bash

# Detect if the DC-SCM LEDs are present in the running kernel and use them
# if so. Otherwise, use the standard LED configuration.
#
# Note: This script should always return success or we break
# the BMC boot process and prevent the host from powering on.

if [ ! -d /etc/phosphor-led-manager ]; then
    mkdir -p /etc/phosphor-led-manager
fi

if gpiofind DC_SCM_PWR_LED_L-O > /dev/null; then
    cp -f /usr/share/phosphor-led-manager/power-led-config-dc-scm.json /etc/phosphor-led-manager/power-led-config.json
else
    cp -f /usr/share/phosphor-led-manager/power-led-config-default.json /etc/phosphor-led-manager/power-led-config.json
fi

exit 0