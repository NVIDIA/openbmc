#!/bin/bash

# Configuration System Bus: HMC Temperature Sensor Bus 3 (HMC <-> FPGA Bus)
# Slave Read-only EEPROM on i2c bus 3 with slave id 0x4f. 0x1000 is the address
# Range of the i2c slave backend subsystem. Hence the final address is 0x104f
I2C_FPGA_HMC_SLAVE_TYPE_RO=slave-24c512ro
I2C_FPGA_HMC_BUS_RO=3
I2C_FPGA_HMC_RO_SLAVE_ADDRESS=4f
I2C_FPGA_HMC_SLAVE_FILE=/sys/bus/i2c/devices/i2c-$I2C_FPGA_HMC_BUS_RO/$I2C_FPGA_HMC_BUS_RO-10$I2C_FPGA_HMC_RO_SLAVE_ADDRESS/name
I2C_FPGA_HMC_SLAVE_MEM_FILE=/sys/bus/i2c/devices/$I2C_FPGA_HMC_BUS_RO-10$I2C_FPGA_HMC_RO_SLAVE_ADDRESS/slave-eeprom
I2C_FPGA_HMC_NEW_DEV_PATH=/sys/bus/i2c/devices/i2c-$I2C_FPGA_HMC_BUS_RO/new_device

# HMC Temp Sensor
HMC_TEMP_SENSOR_PATH_INPUT=/sys/class/hwmon/hwmon0/temp1_input
HMC_TEMP_SENSOR_PATH_MAX=/sys/class/hwmon/hwmon0/temp1_max

# global variable for EEPROM write
declare -a data_array

# EEPROM Offset for HMC Temp and Threshold
# 0xF0 = HMC Temp (4 bytes)
# 0xF4 = HMC Temp Threshold (4 bytes)
HMC_TEMP_AND_THRESHOLD_EEPROM_OFFSET=240
HMC_TEMP_AND_THRESHOLD_SIZE=8

function i2c_slave_create()
{
    ## Create only if the slave does not exists
    if [ ! -f "$I2C_FPGA_HMC_SLAVE_FILE" ]; then
        echo $I2C_FPGA_HMC_SLAVE_TYPE_RO '0x10'$I2C_FPGA_HMC_RO_SLAVE_ADDRESS > $I2C_FPGA_HMC_NEW_DEV_PATH
    fi

    ## Check if the slave file now exists
    if [ ! -f "$I2C_FPGA_HMC_SLAVE_FILE" ]; then
        echo "Failed to create I2C Slave File" | systemd-cat -t hmc-temp-sensor.sh
        return 1
    fi

    return 0
}

function validate_temp_sensor_max_path()
{
    declare -i sleep_cnt=0
    while [ ! -e "$HMC_TEMP_SENSOR_PATH_MAX" ]
    do
        sleep 10
        sleep_cnt=$sleep_cnt+1
        if [ $sleep_cnt -ge 8 ];then
            echo "HMC Temp Sensor Path invalid! Exiting" | systemd-cat -t hmc-temp-sensor.sh
            return 1
        fi
    done

    return 0
}

#
# Set Thermal Threshold
# Set last 4 bytes for threshold
#

function set_therm_threshold()
{
    local max_temp=85000

    if [ -e "$HMC_TEMP_SENSOR_PATH_MAX" ]
    then
        echo $max_temp > $HMC_TEMP_SENSOR_PATH_MAX
    fi

    # 85000 = 0x014c08
    # Offset 0x04 Byte 1 = Fractional Value     = 0x00
    # Offset 0x05 Byte 2 = LSB Integer Value    = 0x08
    # Offset 0x06 Byte 3 = Byte3 Integer Value  = 0x4c
    # Offset 0x07 Byte 4 = MSB Integer Value    = 0x01

    local integer_hex=014C08
    local fractional_hex=00
    local i
    local j

    for ((i=0, j=4; i<${#integer_hex}; i+=2, j++)); do
      local byte="${integer_hex:i:2}"
      data_array[$j]=$byte
    done

    for ((i=0, j=7; i<${#fractional_hex}; i+=2, j++)); do
      local byte="${fractional_hex:i:2}"
      data_array[$j]=$byte
    done
}

#
# Sets first 4 bytes for current temp
# Format:
#   4 Bytes
#    Byte 1 : Fractional Value (offset 0x00)
#    Byte 2 : LSB Integer Value (offset 0x01)
#    Byte 3 : Byte3 Integer Value (offset 0x02)
#    Byte 4 : MSB Integer Value (offset 0x03)
#
#   E.g.
#   27.275 is 0x00001B46 =>
#   Byte 1 0x46 goes at offset 0x00. (Fractional)
#   Byte 2 0x1B goes at offset 0x01.
#   Byte 3 0x00 goes at offset 0x02.
#   Byte 4 0x00 goes at offset 0x03.


function update_curr_temp()
{
    local curr_temp=$(<$HMC_TEMP_SENSOR_PATH_INPUT)
    curr_temp=$(echo "scale=5; $curr_temp/1000" | bc)
    local binary=$(echo "obase=2; scale=0; $curr_temp" | bc)
    binary=$(printf "%033.8f" $binary)
    local integer_bits=$(echo $binary | cut -d "." -f 1)
    local fractional_bits=$(echo $binary | cut -d "." -f 2)

    #
    # Check if the number is negative
    # Get its two's complement
    #
    if [[ $integer_bits -lt 0 ]]
    then
        integer_bits=$(echo $integer_bits | tr "-" 0)
        c1=$(tr 01 10 <<< $integer_bits)
        integer_bits=($c1+1)
    fi

    local integer_hex=$(printf "%06X\n" $((2#$integer_bits)))
    local fractional_hex=$(printf "%02X\n" $((2#$fractional_bits)))
    local i
    local j


    for ((i=0, j=0; i<${#integer_hex}; i+=2, j++)); do
      local byte="${integer_hex:i:2}"
      data_array[$j]=$byte
    done

    for ((i=0, j=3; i<${#fractional_hex}; i+=2, j++)); do
      local byte="${fractional_hex:i:2}"
      data_array[$j]=$byte
    done

}

#
# Update the EEPROM
#
function eeprom_write()
{
    declare -a b
    declare -i i=0
    for i in $(seq 0 7); do b[$i]="${data_array[$i]}"; done

    # Write HMC temp and threshold to EEPROM
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]}\\x${b[7]}\\x${b[6]}\\x${b[5]}\\x${b[4]} | dd of=$I2C_FPGA_HMC_SLAVE_MEM_FILE bs=1 count=$HMC_TEMP_AND_THRESHOLD_SIZE seek=$HMC_TEMP_AND_THRESHOLD_EEPROM_OFFSET status=none
}

function setup()
{
    sleep 5
    local ret

    #
    # If Temp Sensor Max Path exists then return 0 and no compute happens
    #
    validate_temp_sensor_max_path
    ret=$?
    if [[ $ret -ne 0 ]]
    then
        return $ret
    fi

    #
    # If Slave File exists then return 0 and no compute happens
    #
    i2c_slave_create
    ret=$?
    if [[ $ret -ne 0 ]]
    then
        return $ret
    fi

    #
    # Set Thermal Threshold - to happen on setup to populate data_array
    #
    set_therm_threshold

    return 0
}

############################### main ##########################################

setup
if [[ $? -eq 1 ]]
then
    exit 1
fi

while true; do
    update_curr_temp
    eeprom_write
    sleep 0.5
done

