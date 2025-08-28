#!/bin/bash

for i in {1..60}
do
    ObjpathPresent=$(busctl tree xyz.openbmc_project.FruDevice | grep -E "/xyz/openbmc_project/FruDevice/PG548|/xyz/openbmc_project/FruDevice/P4129")
    if [ -n "$ObjpathPresent" ]; then
        exit 0
    fi
    sleep 1
done
echo "ERROR: Could not identify the platform type. Loading default pldm fw-update config file."
