#!/bin/bash

#######################################
# Create FRU EEPROM devices that are behind the FPGA
#
# FRU EEPROMs do not respond until after the FPGA_READY.
# If the kernel tries to mount these EEPROMs from the 
# device tree (DT) before FPGA_READY it will fail.
#
# Note: The HMC releases FPGA from reset. EEPROM binding must
# happen after HMC_READY-I asserts.
#
# WARNING: Driver bind for I2C muxes must occur prior to EEPROM
# driver binding
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Always
create_eeprom_devices(){
    # I2C-1

    # Module 1 FRU EEPROM (Device ID: 24AA64) - 24c64 - 0x50
    # Skip manually binding it and allow entity-manager to do
    # autodetection instead since the device doesn't always
    # exist on all of our platform configurations (i.e. L6 vs.
    # L10 hardware).

    # CBC 0 and 1 FRU EEPROM
    echo 24c02 0x54 > /sys/class/i2c-dev/i2c-1/device/new_device
    echo 24c02 0x55 > /sys/class/i2c-dev/i2c-1/device/new_device

    # IC2-2
    # HMC FRU EEPROM (Device ID: AT24C02D)
    echo 24c02 0x57 > /sys/class/i2c-dev/i2c-2/device/new_device
    # Module 0 FRU EEPROM (Device ID: 24AA64)
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-2/device/new_device
    # CBC 2 and 3 FRU EEPROM
    echo 24c02 0x54 > /sys/class/i2c-dev/i2c-2/device/new_device
    echo 24c02 0x55 > /sys/class/i2c-dev/i2c-2/device/new_device


    # IC2-4
    # Module 0 Aux EEPROM
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-4/device/new_device

    # I2C-6
    # PDB FRU EEPROM (Device ID: M24C02) - Bianca - 24c02 0x50
    # PDB FRU EEPROM (Device ID: M24256) - Ariel - 24c256 0x50
    # Allow entity-manager to do autodetection here since the
    # EEPROM chip addressing mode is different between them and
    # 8-bit vs. 16-bit autodetection works correctly with these
    # two chips.

    # I2C-9
    # Module 0 Aux EEPROM (Device ID: 24AA64)
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-9/device/new_device
    # Module 1 Aux EEPROM
    echo 24c64 0x51 > /sys/class/i2c-dev/i2c-9/device/new_device

    # I2C-14 and I2C-15
    # BF3 EEPROM (Device ID: BR24G128NUX)
    echo 24c128 0x50 > /sys/class/i2c-dev/i2c-14/device/new_device
    echo 24c128 0x50 > /sys/class/i2c-dev/i2c-15/device/new_device

    # I2C-21
    # Module 0, IO Board FRU EEPROM (Device ID: 24AA64)
    # I2C MUX, Bus5 @0x72
    # MUX Channel-1, Virtual I2C21 @0x50
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-21/device/new_device

    # I2C-23
    # MUX Channel-3, Virtual I2C23
    # FrontIO FRU EEPROM
    echo 24c128 0x57 > /sys/class/i2c-dev/i2c-23/device/new_device
 

    # I2C-33
    # Module 1, IO Board FRU EEPROM (Device ID: 24AA64)
    # I2C MUX, Bus5 @0x76
    # MUX Channel-1, Virtual I2C33 @0x50
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-33/device/new_device
    return 0
}

#######################################
# Create FRU EEPROM devices that are behind the system power-on
#
# These FRU EEPROMs do not respond until after the system power-on.
# If the kernel tries to mount these EEPROMs from the
# device tree (DT) before the system power-on it will fail.
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Always
create_poweron_eeprom_devices(){
    # I2C-14 and I2C-15
    # IPEX Left FRU
    if [ ! -d "/sys/bus/i2c/drivers/at24/14-0055" ]; then
        echo 24c128 0x55 > /sys/class/i2c-dev/i2c-14/device/new_device
    fi
    # HDD BP Left FRU
    if [ ! -d "/sys/bus/i2c/drivers/at24/14-0056" ]; then
        echo 24c128 0x56 > /sys/class/i2c-dev/i2c-14/device/new_device
    fi
    # IPEX Right FRU
    if [ ! -d "/sys/bus/i2c/drivers/at24/15-0055" ]; then
        echo 24c128 0x55 > /sys/class/i2c-dev/i2c-15/device/new_device
    fi
    # HDD Right FRU
    if [ ! -d "/sys/bus/i2c/drivers/at24/15-0056" ]; then
        echo 24c128 0x56 > /sys/class/i2c-dev/i2c-15/device/new_device
    fi
    # I2C-17
    # CX8 Topology for E1S BP FRU EEPROM
    if [ ! -d "/sys/bus/i2c/drivers/at24/17-0056" ]; then
        echo 24c128 0x56 > /sys/class/i2c-dev/i2c-17/device/new_device
    fi
    # I2C-21
    # OSFP Board Left
    if [ ! -d "/sys/bus/i2c/drivers/at24/21-0052" ]; then
        echo 24c128 0x52 > /sys/class/i2c-dev/i2c-21/device/new_device
    fi
    # I2C-29
    # CX8 Topology for E1S BP FRU EEPROM
    if [ ! -d "/sys/bus/i2c/drivers/at24/29-0056" ]; then
        echo 24c128 0x56 > /sys/class/i2c-dev/i2c-29/device/new_device
    fi
    # I2C-33
    # OSFP Board Right
    if [ ! -d "/sys/bus/i2c/drivers/at24/33-0052" ]; then
        echo 24c128 0x52 > /sys/class/i2c-dev/i2c-33/device/new_device
    fi
    # I2C-54
    # 1G NIC
    # I2C MUX, Bus25 @0x70, MUX Channel-2
    if [ ! -d "/sys/bus/i2c/drivers/at24/54-0051" ]; then
        echo 24c128 0x51 > /sys/class/i2c-dev/i2c-54/device/new_device
    fi
}

#######################################
# Remove FRU EEPROM devices that are behind the system power-off
#
# These FRU EEPROMs are not present when the system power-off.
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Always
remove_poweron_eeprom_devices(){
    # I2C-14 and I2C-15
    # IPEX Left FRU
    if [ -d "/sys/bus/i2c/drivers/at24/14-0055" ]; then
        echo 0x55 > /sys/class/i2c-dev/i2c-14/device/delete_device
    fi
    # HDD BP Left FRU
    if [ -d "/sys/bus/i2c/drivers/at24/14-0056" ]; then
        echo 0x56 > /sys/class/i2c-dev/i2c-14/device/delete_device
    fi
    # IPEX Right FRU
    if [ -d "/sys/bus/i2c/drivers/at24/15-0055" ]; then
        echo 0x55 > /sys/class/i2c-dev/i2c-15/device/delete_device
    fi
    # HDD Right FRU
    if [ -d "/sys/bus/i2c/drivers/at24/15-0056" ]; then
        echo 0x56 > /sys/class/i2c-dev/i2c-15/device/delete_device
    fi
    # I2C-21
    # OSFP Board Left
    if [ -d "/sys/bus/i2c/drivers/at24/21-0052" ]; then
        echo 0x52 > /sys/class/i2c-dev/i2c-21/device/delete_device
    fi
    # I2C-33
    # OSFP Board Right
    if [ -d "/sys/bus/i2c/drivers/at24/33-0052" ]; then
        echo 0x52 > /sys/class/i2c-dev/i2c-33/device/delete_device
    fi
    # I2C-54
    # 1G NIC
    # I2C MUX, Bus25 @0x70, MUX Channel-2
    if [ -d "/sys/bus/i2c/drivers/at24/54-0051" ]; then
        echo 0x51 > /sys/class/i2c-dev/i2c-54/device/delete_device
    fi
}
