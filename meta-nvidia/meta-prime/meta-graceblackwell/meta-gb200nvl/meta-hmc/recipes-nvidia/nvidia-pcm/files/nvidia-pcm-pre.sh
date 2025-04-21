#!/bin/bash

for i in {1..60}
do
    ObjpathPresent=$(busctl tree xyz.openbmc_project.FruDevice | grep "/xyz/openbmc_project/FruDevice/PG548")
    if [ -n "$ObjpathPresent" ]; then
        exit 0
    fi
    sleep 1
done
echo "ERROR: Could not identify the platform type. Loading default pldm fw-update config file."
