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
    # Module 1 FRU EEPROM
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-1/device/new_device
    # UT 3.0 U155 (Pin A14, A15)
    echo 24c02 0x57 > /sys/class/i2c-dev/i2c-1/device/new_device

    # IC2-2
    # HMC FRU EEPROM
    echo 24c02 0x57 > /sys/class/i2c-dev/i2c-2/device/new_device
    # Module 0 FRU EEPROM
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-2/device/new_device

    # I2C-4
    # Module 0 Aux EEPROM
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-4/device/new_device

    # I2C-5
    # UT 3.0 U171 (Pin B23, B24)
    echo 24c02 0x57 > /sys/class/i2c-dev/i2c-5/device/new_device

    # I2C-6
    # PDB FRU EEPROM
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-6/device/new_device
    # UT 3.0 U160 (Pin B14, B15)
    echo 24c02 0x57 > /sys/class/i2c-dev/i2c-6/device/new_device

    # I2C-8
    # UT 3.0 U221 (Pin A32, A33)
    echo 24c02 0x57 > /sys/class/i2c-dev/i2c-8/device/new_device

    # I2C-9
    # Module 0 Aux EEPROM
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-9/device/new_device
    # Module 1 Aux EEPROM
    echo 24c64 0x51 > /sys/class/i2c-dev/i2c-9/device/new_device
    # UT 3.0 U151 (Pin B11, B12)
    echo 24c02 0x57 > /sys/class/i2c-dev/i2c-9/device/new_device

    # I2C-15
    # UT 3.0 U147 (Pin B5, B6)
    echo 24c02 0x57 > /sys/class/i2c-dev/i2c-15/device/new_device

    # I2C-21
    # Module 0, IO Board FRU EEPROM
    # I2C MUX, Bus5 @0x72
    # MUX Channel-1, Virtual I2C21 @0x50
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-21/device/new_device

    # I2C-33
    # Module 1, IO Board FRU EEPROM
    # I2C MUX, Bus5 @0x76
    # MUX Channel-1, Virtual I2C33 @0x50
    echo 24c64 0x50 > /sys/class/i2c-dev/i2c-33/device/new_device
    return 0
}
