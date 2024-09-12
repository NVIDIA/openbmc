#!/bin/bash

#######################################
# Manually bind GPIO expander driver
#
# This function enables the ability to manually bind the driver
# to the IO Expander.
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Device driver bind sucessfull
#   1 Failed bind driver
bind_gpio_expanders()
{
    if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "1-0024"` ]]; then
        echo "Could not find 1-0024, manually binding PCA driver"
        echo "1-0024" > /sys/bus/i2c/drivers/pca953x/bind
        rc=$?

        if [[ $rc -ne 0 ]]; then
            echo "[ERROR] Failed to bind IO Expander 1-0024 to pca9555 driver"
            return 1
        else
            echo "IO Expander 1-0024 has been bound to /sys/bus/i2c/drivers/pca953x"
        fi
    else
       echo "found driver already so will not bind"
       exit 0
    fi
    exit $rc
}

## Main

bind_gpio_expanders
