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
erot_reset_delay=10

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

    # Default manual boot enabled to false
    local manual_boot_enabled="false"

    #enable direct access to the erot
    i2ctransfer -y $BUS w2@0x60 0xc0 0x01

    #query manual boot mode status
    local cmd_output=$(i2ctransfer -y $BUS w1@0x28 0x15 r3)

    #command status is the second byte of the command output
    local cmd_status=$(echo $cmd_output | awk '{print $2}')

    #check if command is supported. 0xff means command not supported
    if [ "$cmd_status" = "0xff" ]; then
        #fall back to pseudo MCTP mode command. Note that this mode is not well
        #supported and have been known to cause ERoT timeouts. See NVbug
        #5201593. Allowing this option to avoid rev-lock with ERoTs.
        echo "[WARNING] Manual boot query command not supported, using vdm command in pseudo MCTP mode"
        manual_boot_query_message="0xf 0xf 0x1 0x1 0x0 0x0 0xc8 0x7f 0x47 0x16 0x0 0x0 0x81 0x1 0x11 0x1 0x02"

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
            manual_boot_enabled="true"
        fi
    else
        #Byte2 of the command output is the boot status. See Query Manual Boot
        #command in Glacier Firmware Design Document for more details.
        boot_status=$(echo $cmd_output | awk '{print $3}')
        if [[ "${cmd_status}" -eq "0x00" && "${boot_status}" -eq "0x01" ]]; then
            manual_boot_enabled="true"
        fi
    fi

    #disable direct access to the erot after we are done
    i2ctransfer -y $BUS w2@0x60 0xc0 0x00

    if [ "${manual_boot_enabled}" = "true" ]; then
        echo "Manual boot is enabled on bus $BUS, skip CPU ERoT authentication"
        return 1
    else
        return 0
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

    #enable direct access to the erot
    i2ctransfer -y $BUS w2@0x60 0xc0 0x01

    #query erot boot status
    local cmd_output=$(i2ctransfer -y $BUS w1@0x28 0x14 r10)

    #command status is the second byte of the command output
    local cmd_status=$(echo $cmd_output | awk '{print $2}')

    #check if command is supported. 0xff means command not supported
    if [ "$cmd_status" = "0xff" ]; then
        #fall back to pseudo MCTP mode command. Note that this mode is not well
        #supported and have been known to cause ERoT timeouts. See NVbug
        #5201593. Allowing this option to avoid rev-lock with ERoTs.
        echo "[WARNING] Boot status query command not supported, using vdm command in pseudo MCTP mode"
        i2ctransfer -y $BUS w17@0x28 0xf 0xe 0x1 0x1 0x0 0x0 0xc8 0x7f 0x47 0x16 0x0 0x0 0x81 0x1 0x5 0x1 0x89

        sleep 1

        #get the response to the vdm command
        cmd_output=$(i2ctransfer -y $BUS w1@0x28 0x0D r73)

        #Byte offset of Authentication Status in command output
        auth_status_byte=25
    else
        #add sleep here to avoid checking status too frequently
        sleep 1

        if [ "$cmd_status" != "0x00" ]; then
            echo "[WARNING] Boot status query command returned error ${cmd_status}, retrying."
            return 0
        fi

        #Byte offset of Authentication Status in command output. See Boot
        #Status Query command for more details.
        auth_status_byte=9
    fi

    #disable direct access to the erot after we are done
    i2ctransfer -y $BUS w2@0x60 0xc0 0x00

    #auth status is bit 8-15 of Boot Status Code. Obtain from command output
    auth_status=$(echo $cmd_output | awk -v byte="$auth_status_byte" '{print $byte}')

    #parsing for primary and secondary firmware authentication status as defined
    #in the Glacier Firmware Design Document
    local sec_fw_auth_status=$(echo $(($auth_status >> 4)))
    local pri_fw_auth_status=$(echo $(($auth_status & 0x0F)))
    if ([ $sec_fw_auth_status -eq 0 ] || [ $sec_fw_auth_status -eq 15 ]) || ([ $pri_fw_auth_status -eq 0 ] || [ $pri_fw_auth_status -eq 15 ]); then
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

    #Add arbitrary buffer to the polling timeout to allow ERoT to complete
    #authentication
    local timeout_buffer=3
    local auth_polling_timeout=$((polling_timeout-erot_reset_delay+timeout_buffer))
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

        while [ $count -lt $auth_polling_timeout ]; do

            if [[ "$fpga0_status" -eq 0 ]]; then
                check_cpu_erot_auth "$fpga0_bus"
                fpga0_status=$?
                ((count++))
            fi

            if [[ "$fpga1_status" -eq 0 ]]; then
                check_cpu_erot_auth "$fpga1_bus"
                fpga1_status=$?
                ((count++))
            fi


            if [[ "$fpga0_status" -eq 1 && "$fpga1_status" -eq 1 ]]; then
                break
            fi
        done

    elif [[ "$fpga0_ready" -eq 1 && "$fpga1_ready" -eq 0 ]]; then
        
        check_cpu_erot_manual_boot "$fpga0_bus"
        if [ $? -eq 1 ]; then
            break
        fi

        while [ $count -lt $auth_polling_timeout ]; do
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

        while [ $count -lt $auth_polling_timeout ]; do
            check_cpu_erot_auth "$fpga1_bus"
            fpga1_status=$?
            if [ "$fpga1_status" -eq 1 ]; then
                break
            else
                ((count++))
            fi
        done

    fi
    
    if [ $count -ge $auth_polling_timeout ]; then
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

    #Delay to allow ERoT to become ready. In a case of where there was a ERoT
    #Firmware update, the ERoT will perform background copy and reset itself.
    #During the reset, the ERoT may not respond to I2C commands.  This delay
    #allows for the ERoT to safely complete the background copy and reset.
    sleep $erot_reset_delay

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
