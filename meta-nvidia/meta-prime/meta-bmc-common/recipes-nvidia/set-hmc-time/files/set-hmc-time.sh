#!/bin/bash

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

set_hmc_time() {
    local current_datetime=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
    output=`curl -s -k -X PATCH http://HMC_0/redfish/v1/Managers/HGX_BMC_0 -d "{\"DateTime\": \"${current_datetime}\"}"`

    # If return code isn't 0, then Redfish didn't respond
    if [[ $? -ne 0 ]]; then
        return 1;
    # If the RF command returns a failed message, or if it fails to send, then the word "failed" will be present
    elif [[ `echo $output |grep error | wc -l` != 0 ]]; then
        return 1;
    else
        return 0;
    fi
}

#set -e
Count=1
until [[ $Count -gt 10 ]]
do
    echo "Attempting to set HMC time: ${Count}/10"

    set_hmc_time
    rc=$?

    if [[ $rc -eq 0 ]]; then
        echo "HMC time was set successfully."
        exit 0
    fi
    
    sleep 5
    ((Count++))
done

echo "Error: Cannot sync the HMC's RTC after 10 attempts."
exit 1
