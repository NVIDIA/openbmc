#!/bin/bash

# NOTE: Get GPIO line names from nvidia-gb200nvl-hmc-core.dtsi

# Inherit Logging libraries
source /etc/default/nvidia_event_logging.sh

# Inherit bmc functions library
source /usr/bin/mc_lib.sh

# Inherit FPGA power sequence library
source /usr/bin/fpga_power_sequence.sh

# Inherit multi-module library
source /usr/bin/multi_module_detection.sh

# Get platform variables
source /etc/default/platform_var.conf

#######################################
# Set initial HMC GPIO out states
# ARGUMENTS:
#   None
# RETURN:
#   None
hmc_set_initial_gpio_out()
{

    set_fpga_rst $LOW
}

#######################################
# Assert HMC_READY-O
# ARGUMENTS:
#   None
# RETURN:
#   0 - HMC_READY-O is asserted
#   1 - Failed to assert HMC_READY-O
set_hmc_ready()
{    
    if ! [ -f ${HMC_READY_CONTROL} ]; then
        echo "[ERROR] ${HMC_READY_CONTROL} does not exist!"
        return 1
    fi
    # Assert HMC_READY-O
    echo 1 > ${HMC_READY_CONTROL}

    # Confirm HMC_READY-O is asserted
    hmc_ready_val=$(cat ${HMC_READY_CONTROL})
    if [[ "${hmc_ready_val}" == 1 ]]; then
        echo "HMC_READY-O has been asserted"
        return 0
    else
        echo "[ERROR] Failed to assert HMC_READY-O"
        return 1
    fi
}

#######################################
# Execute required steps before asserting HMC_READY-O signal
# 1. Execute FPGA power sequence
#
# ARGUMENTS:
#   None
# RETURN:
#   None
# EXIT:
#   0 HMC_READY-O has been asserted
#   1 HMC_READY-O not asserted, due to failure in ready sequence
hmc_ready_sequence()
{
    discover_modules
    
    #Primary FPGA
    execute_fpga_power_sequence
    rc=$?

    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Will not assert HMC_READY-O"
        exit 1
    fi

    #Check and log preliminary status of secondary FPGAs
    p_secondary_fpgardy_status

    check_rw_filesystems
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Filesystem mount check failure"
        exit 1
    fi

    check_rofs
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] HMC booted in ROFS, Read-Only mode"
        exit 1
    fi

    # Module Temp Sensor Setting.
    #set_module_temp_sensor_threshold.sh
    echo "[WARNING] GPU Temp thresholds need to be set"

    # Assert HMC_READY-O
    set_hmc_ready
    rc=$?
    if [[ $rc -ne 0 ]]; then
        exit 1
    fi
    phosphor_log "hmc_ready.sh completed" $sevNot

    exit 0

}

## Main

hmc_ready_sequence
