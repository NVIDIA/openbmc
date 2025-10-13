#!/bin/bash

# Detect if the DC-SCM buttons are present in the running kernel and use them
# if so. Otherwise, use the standard button configuration.
#
# Note: This script should always return success or we break
# the BMC boot process and prevent the host from powering on.


if gpiofind DC_SCM_PWR_BTN_L-I > /dev/null; then
    cp -f /etc/default/obmc/gpio/gpio_defs_dc_scm.json /etc/default/obmc/gpio/gpio_defs.json
else
    cp -f /etc/default/obmc/gpio/gpio_defs_default.json /etc/default/obmc/gpio/gpio_defs.json
fi

exit 0