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
    # Module 1 FRU EEPROM (Device ID: 24AA64)
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-1/device/new_device
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
    # PDB FRU EEPROM (Device ID: M24C02)
    echo 24c02 0x50 > /sys/class/i2c-dev/i2c-6/device/new_device

    # I2C-9
    # Module 0 Aux EEPROM (Device ID: 24AA64)
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-9/device/new_device
    # Module 1 Aux EEPROM
    echo 24c64 0x51 > /sys/class/i2c-dev/i2c-9/device/new_device

    # I2C-14 and I2C-15
    # BF3 EEPROM (Device ID: BR24G128NUX)
    echo 24c128 0x50 > /sys/class/i2c-dev/i2c-14/device/new_device
    # IPEX Left FRU
    echo 24c128 0x55 > /sys/class/i2c-dev/i2c-14/device/new_device
    # HDD BP Left FRU
    echo 24c128 0x56 > /sys/class/i2c-dev/i2c-14/device/new_device
    echo 24c128 0x50 > /sys/class/i2c-dev/i2c-15/device/new_device
    # IPEX Right FRU
    echo 24c128 0x55 > /sys/class/i2c-dev/i2c-15/device/new_device
    # HDD Right FRU
    echo 24c128 0x56 > /sys/class/i2c-dev/i2c-15/device/new_device


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
