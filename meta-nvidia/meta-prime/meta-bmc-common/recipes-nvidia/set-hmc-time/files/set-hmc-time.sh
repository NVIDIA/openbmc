#!/bin/bash

set_hmc_time() {
    local current_datetime=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
    if curl -s -k -X PATCH http://HMC_0/redfish/v1/Managers/HGX_BMC_0 -d "{\"DateTime\": \"${current_datetime}\"}"; then
        echo "Set HMC time successfully."
    else
        echo "Set HMC time failed."
    fi
}

current_datetime=$(set_hmc_time)
echo "$current_datetime"

