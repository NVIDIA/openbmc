#!/bin/bash

# Inherit Logging libraries
source /etc/default/nvidia_event_logging.sh

#######################################
# Discover state of every discovered 
# FPGA_READY pin
#
# ARGUMENTS:
#   None
# RETURN:
#   None
secondary_fpgardy_status()
{
    # The idea is to only check FPGA_READY_i 
    # if the module has been detected as "present"
    source /etc/default/platform_var.conf
    MODULE_PRSNT_ARR=($(cat $MODULE_PRSNT_FILE))
    if [[ "${MODULE_PRSNT_ARR[@]// /}" == "" ]]; then
        echo "Could not source PRSNT modules"
    fi
    found=0
    for pin_i in "${MODULE_PRSNT_ARR[@]}"; do
        if [[ "$pin_i" == "$FPGA_NUM" ]]; then
            ((found++))
            echo "FPGA_READY on Module $(($pin_i + 1)) returns 0"
            phosphor_log "FPGA $(($pin_i + 1)) is down, module management inhibited for Module $(($pin_i + 1))" $sevErr
        fi
    done

    if [[ $found == "0" ]]; then
        echo " FPGA $FPGA_NUM not found in PRESENT modules."
    fi
}

###
### Main
###
FPGA_NUM=$1
((FPGA_NUM--))
echo "Checking status of FPGA_$FPGA_NUM"
secondary_fpgardy_status