#!/bin/bash

# check if MC_READY-I is unused or not 
if [ "$(gpioinfo | grep -i "HMC_READY-I" | grep -c "unused")" -eq 0 ]; then
    echo "HMC_READY-I is in use, exiting..."
    exit 1
fi

# check if recovery_config is populated or not
if ! busctl tree xyz.openbmc_project.EntityManager | grep -q "/xyz/openbmc_project/inventory/system/recovery_config"; then
    echo "recovery_config not found, exiting..."
    exit 1
fi

exit 0