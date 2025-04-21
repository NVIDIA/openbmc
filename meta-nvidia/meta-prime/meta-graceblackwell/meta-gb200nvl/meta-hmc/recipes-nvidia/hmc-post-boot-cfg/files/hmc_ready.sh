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
# Check if CPU Erot manual boot is enabled
#
# ARGUMENTS:
#   i2c bus 
# RETURN:
#   0 - manual boot is disabled
#   1 - manual boot is enabled
check_cpu_erot_manual_boot() {
    local BUS=$1
    
     manual_boot_query_message="0xf 0xf 0x1 0x1 0x0 0x0 0xc8 0x7f 0x47 0x16 0x0 0x0 0x81 0x1 0x11 0x1 0x02"
    
    #passthrough on the fpga
    i2ctransfer -y $BUS w2@0x60 0xc0 0x01

    #check if manual boot is enabled
    arr=($manual_boot_query_message)
    len=$((${#arr[@]}+1))

    #0xA4 is the 8bit address of the destination 0x52
    #CRC is calculated for "A4 ${manual_boot_query_message}"
    crc="0xb3"
    i2ctransfer -y $BUS w${len}@0x28 ${manual_boot_query_message} ${crc}

    sleep 0.5

    ret=$(i2ctransfer -y $BUS w1@0x28 0x0d r20)
    response=($ret)
    echo "ERoT manual boot response: ${response[@]}"

    command=${response[15]}
    completion=${response[17]}
    status=${response[18]}
    
    # If command fails, do not skip authentication
    # Wait for us to timeout
    if [[ "${command}" -eq "0x11" && "${completion}" -eq "0x00" && "${status}" -eq "0x01" ]]; then
        echo "Manual boot is enabled on bus $BUS, skip CPU ERoT authentication"
        return 1
    fi

    return 0
    
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

    sleep 0.5

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
#  fpga0_bus value
#  fpga0_ready value
#  fpga1_bus value
#  fpga1_ready value
# RETURN:
#   None
check_fpga_ready_and_erot_auth() {

    local fpga0_bus=$1
    local fpga0_ready=$2
    local fpga1_bus=$3
    local fpga1_ready=$4

    if [[ "$fpga0_ready" -eq 0 && "$fpga1_ready" -eq 0 ]]; then
        echo "FPGA0 and FPGA1 are not ready, do not authenticate CPU ERoTs"
        return
    fi

    local count=0
    local fpga0_status=0
    local fpga1_status=0

    # There may be cases where either fpga0 or fpga1 is
    # ready, or both are ready.
    # Implement this way to parallelize the polling
    if [[ "$fpga0_ready" -eq 1 && "$fpga1_ready" -eq 1 ]]; then

        check_cpu_erot_manual_boot "$fpga0_bus"
        if [ $? -eq 1 ]; then
            echo "Skip authentication for CPU ERoT exposed by fpga0"
            fpga0_status=1
        fi

        check_cpu_erot_manual_boot "$fpga1_bus"
        if [ $? -eq 1 ]; then
            echo "Skip authentication for CPU ERoT exposed by fpga1"
            fpga1_status=1  
        fi

        while [ $count -lt $polling_timeout ]; do

            if [[ "$fpga0_status" -eq 0 ]]; then
                check_cpu_erot_auth "$fpga0_bus"
                fpga0_status=$?
            fi

            if [[ "$fpga1_status" -eq 0 ]]; then
                check_cpu_erot_auth "$fpga1_bus"
                fpga1_status=$?
            fi


            if [[ "$fpga0_status" -eq 1 && "$fpga1_status" -eq 1 ]]; then
                break
            else
                ((count++))
            fi
        done

    elif [[ "$fpga0_ready" -eq 1 && "$fpga1_ready" -eq 0 ]]; then
        
        check_cpu_erot_manual_boot "$fpga0_bus"
        if [ $? -eq 1 ]; then
            break
        fi

        while [ $count -lt $polling_timeout ]; do
            check_cpu_erot_auth "$fpga0_bus"
            fpga0_status=$?
            if [ "$fpga0_status" -eq 1 ]; then
                break
            else
                ((count++))
            fi
        done

    elif [[ "$fpga0_ready" -eq 0 && "$fpga1_ready" -eq 1 ]]; then

        check_cpu_erot_manual_boot "$fpga1_bus"
        if [ $? -eq 1 ]; then
            break
        fi

        while [ $count -lt $polling_timeout ]; do
            check_cpu_erot_auth "$fpga1_bus"
            fpga1_status=$?
            if [ "$fpga1_status" -eq 1 ]; then
                break
            else
                ((count++))
            fi
        done

    fi
    
    if [ $count -eq $polling_timeout ]; then
        echo "Timed out waiting for cpu erot to finish authentication"
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

    check_fpga_ready_and_erot_auth 1 $fpga0_ready 2 $fpga1_ready

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
