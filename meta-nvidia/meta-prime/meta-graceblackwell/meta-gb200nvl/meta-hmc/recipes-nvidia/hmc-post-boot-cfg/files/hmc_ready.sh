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

polling_timeout=20

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
# Check if CPU Erot passed authentcation
# 1. Execute FPGA power sequence
#
# ARGUMENTS:
#   i2c bus to check on
# RETURN:
#   0 - means auth not done
#   1 - means auth done
check_cpu_erot_auth() {
    local BUS=$1

    #passthrough on the fpga
    i2ctransfer -y $BUS w2@0x60 0xc0 0x01
    #send vdm command to erot
    i2ctransfer -y $BUS w17@0x28 0xf 0xe 0x1 0x1 0x0 0x0 0xc8 0x7f 0x47 0x16 0x0 0x0 0x81 0x1 0x5 0x1 0x89

    sleep 1

    #get the response to the vdm command
    local output=$(i2ctransfer -y $BUS w1@0x28 0x0D r73)

    local byte25=$(echo $output | awk '{print $25}')

    local upper_nibble=$(echo $(($byte25 >> 4)))
    local lower_nibble=$(echo $(($byte25 & 0x0F)))
    if ([ $upper_nibble -eq 0 ] || [ $upper_nibble -eq 15 ]) || ([ $lower_nibble -eq 0 ] || [ $lower_nibble -eq 15 ]); then
        return 0
    else
        return 1
    fi
}

#######################################
# Execute required steps to check erot auth status
# #
# ARGUMENTS:
#  fpga_ready value
#  i2c bus to be used
# RETURN:
#   None
check_fpga_ready_and_erot_auth() {
    local fpga_ready=$1
    local i2c_bus=$2

    if [ "$fpga_ready" -eq 1 ]; then
        local count=0

        while [ $count -lt $polling_timeout ]; do
            check_cpu_erot_auth "$i2c_bus"
            local status=$?

            if [ "$status" -eq 1 ]; then
                break
            else
                sleep 1
                ((count++))
            fi
        done

        if [ $count -eq $polling_timeout ]; then
            echo "Timed out waiting for cpu erot on bus $i2c_bus to finish authentication"
        fi
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

    # Sync HMC FRU EEPROM to the file
    /usr/bin/hmc_fru_checker.sh
    if [ $? -ne 0 ]; then
        echo "[ERROR] Unable to read HMC FRU"
    fi

    #Primary FPGA
    execute_fpga_power_sequence
    rc=$?

    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Will not assert HMC_READY-O"
        exit 1
    fi

    p_secondary_fpgardy_status

    #Check and log preliminary status of primary FPGA
    count=0
    fpga0_ready=0
    while [ $count -lt $polling_timeout ]; do
        gpio_status=$(get_gpio "$FPGA_READY_NAME")
        if [ "$gpio_status" -eq 1 ]; then
            echo "FPGA0 is ready."
            fpga0_ready=1
            break
        fi
        sleep 1  # Sleep for 1 second before the next check
        ((count++))  # Increment the counter
    done

    #Check and log preliminary status of secondary FPGAs
    count=0
    fpga1_ready=0
    while [ $count -lt $polling_timeout ]; do
        gpio_status=$(get_gpio "$FPGA1_READY_NAME")
        if [ "$gpio_status" -eq 1 ]; then
            echo "FPGA1 is ready."
            fpga1_ready=1
            break
        fi
        sleep 1  # Sleep for 1 second before the next check
        ((count++))  # Increment the counter
    done

    check_fpga_ready_and_erot_auth $fpga0_ready 1
    check_fpga_ready_and_erot_auth $fpga1_ready 2

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
