#!/bin/bash

status=$(systemctl status bmc-boot-complete)

if echo "$status" | grep -q "Active: activating"; then
   echo "bmc-boot-complete still running"
   exit 1
fi

# check if recovery_config is populated or not
if ! busctl tree xyz.openbmc_project.EntityManager | grep -q "/xyz/openbmc_project/inventory/system/recovery_config"; then
    echo "recovery_config not found, exiting..."
    exit 1
fi

exit 0