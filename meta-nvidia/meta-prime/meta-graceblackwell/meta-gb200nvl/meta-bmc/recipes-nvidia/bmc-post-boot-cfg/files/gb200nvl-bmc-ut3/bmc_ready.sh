#!/bin/bash

# NOTE: Get GPIO line names from nvidia-gb200nvl-bmc-core.dtsi

# Inherit Logging libraries
source /etc/default/nvidia_event_logging.sh

# Inherit bmc functions library
source /usr/bin/mc_lib.sh

# Inherit create_eeprom library
source /usr/bin/create_eeprom_devices.sh

# Inherit multi-bianca library
source /usr/bin/multi_module_detection.sh

# Get platform variables
source /etc/default/platform_var.conf

# Get file pointers to system state files:
#     MANUAL_PCI_MUX_SEL_FILE
source /usr/bin/system_state_files.sh

#######################################
# Set initial/default GPIO state
#
# ARGUMENTS:
#   None
# RETURN:
#   None
bmc_set_initial_gpio_out()
{
    echo "Setting GPIO Initial State"
    # Initialize GPIO out state
    # After STBY power is on to aovid creating leaky path
    # Every signal should be set to 0
    echo "Set RUN_POWER_EN-O=0"
    echo 0 > /sys/class/gpio/gpio${sysfs_run_power}/value

    set_gpio_level "PWR_BRAKE_L-O" $LOW

    set_gpio_level "SHDN_REQ_L-O" $LOW

    set_gpio_level "SHDN_FORCE_L-O" $LOW

    set_gpio_level "SYS_RST_IN_L-O" $LOW

    set_gpio_level "GLOBAL_WP_BMC-O" $LOW

    set_gpio_level "HMC_RESET_L-O" $LOW
}

#######################################
# Set Standby Power GPIOs
#
# ARGUMENTS:
#   None
# RETURN:
#   None
bmc_set_stby_pg_gpio_out()
{
    set_gpio_level "PWR_BRAKE_L-O" $HIGH

    set_gpio_level "SHDN_REQ_L-O" $HIGH

    set_gpio_level "SHDN_FORCE_L-O" $HIGH

    # Hold in reset (asserted) after standby power enabled
    set_gpio_level "SYS_RST_IN_L-O" $LOW

}

#######################################
# Assert BMC_READY-O
# ARGUMENTS:
#   None
# RETURN:
#   0 - BMC_READY-O is asserted
#   1 - Failed to assert BMC_READY-O
set_bmc_ready()
{
    if ! [ -f ${BMC_READY_CONTROL} ]; then
        echo "[ERROR] ${BMC_READY_CONTROL} does not exist!"
        return 1
    fi
    # Assert BMC_READY-O
    echo 1 > ${BMC_READY_CONTROL}

    # Confirm BMC_READY-O is asserted
    bmc_ready_val=$(cat ${BMC_READY_CONTROL})
    if [[ "${bmc_ready_val}" == 1 ]]; then
        echo "BMC_READY-O has been asserted"
        return 0
    else
        echo "[ERROR] Failed to assert BMC_READY-O"
        return 1
    fi
}

# Wait for GPIO to  assert
#
# ARGUMENTS:
#  gpioname - the name of gpio of interest
# RETURN:
#   0 gpioname asserted
#   1 gpioname not asserted before timeout
wait_gpio_assert()
{
    local gpioname=$1
    local max_retries=1800
    local delay_secs=0.1
    echo "Waiting for $gpioname to assert high"
    gpival=0
    trycnt=1
    until [[ $gpival -gt 0 || $trycnt -gt $max_retries ]]
    do
        gpival=$(gpioget `gpiofind "$gpioname"`)
        rc=$?
        if [[ $rc -ne 0 ]]; then
            err_msg="Unable to read $gpioname GPIO"
            echo $err_msg
            phosphor_log $err_msg $sevErr
            return 1
        fi
        if [ $gpival -eq 0 ]; then
            sleep $delay_secs
        fi
        ((trycnt++))
    done
    if [ $gpival -eq 0 ]; then
        timeout_secs=$(echo "scale=4; $max_retries*$delay_secs" | bc)
        err_msg="$gpioname failed to assert after $timeout_secs seconds (possible HMC or FPGA FW issue)"
        echo $err_msg
        phosphor_log $err_msg $sevErr
        return 1
    else
        echo "$gpioname = 1"
        return 0
    fi
}

#######################################
# Wait for Standby power
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Standby power asserted
#   1 Standby power not asserted
wait_standby_pwr()
{
    local max_retries=200
    local delay_secs=0.1
    echo 'Waiting for STBY_POWER_PG-I to assert'
    gpival=0
    trycnt=1
    until [[ $gpival -gt 0 || $trycnt -gt $max_retries ]]
    do
        gpival=$(get_stby_power_pg)
        rc=$?
        if [[ $rc -ne 0 ]]; then
            err_msg="Unable to read STBY_POWER_PG-I"
            echo $err_msg
            phosphor_log "$err_msg" $sevErr
            return 1
        fi
        if [ $gpival -eq 0 ]; then
            sleep $delay_secs
        fi
        ((trycnt++))
    done
    if [ $gpival -eq 0 ]; then
        timeout_secs=$(echo "scale=4; $max_retries*$delay_secs" | bc)
        err_msg="STBY_POWER_PG-I failed to assert after $timeout_secs seconds. Disabling STBY_POWER_EN."
        echo $err_msg
        phosphor_log "$err_msg" $sevErr
        set_gpio_level "STBY_POWER_EN-O" $LOW
        return 1
    else
        echo "STBY_POWER_PG-I = 1"
        return 0
    fi
}



#######################################
# Bind I2C MUXes
#
# Bind drivers to all I2C muxes so drivers can then
# be bound to devices behind the muxes
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Always
bind_i2c_muxes()
{

    # I2C Muxes on each GB Module
    # i2c-mux-idle-disconnect flag must be set for each mux using the following command:
    # Example: echo -2 > /sys/bus/i2c/drivers/pca954x/5-007x/idle_state

    # Module 0, I2C5 Mux @0x71
    # Creates virtual Buses 16-19
    echo pca9546 0x71 > /sys/class/i2c-dev/i2c-5/device/new_device
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Failed to bind IO Expander 5-0071 to pca9546 driver"
    else
        echo -2 > /sys/bus/i2c/drivers/pca954x/5-0071/idle_state
        echo "IO Expander 5-0071 has been bound to /sys/bus/i2c/drivers/pca954x"
    fi
    # Module 0, I2C5 Mux @0x72
    # Creates virtual Buses 20-23
    echo pca9546 0x72 > /sys/class/i2c-dev/i2c-5/device/new_device
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Failed to bind IO Expander 5-0072 to pca9546 driver"
    else
        echo -2 > /sys/bus/i2c/drivers/pca954x/5-0072/idle_state
        echo "IO Expander 5-0072 has been bound to /sys/bus/i2c/drivers/pca954x"
    fi
    # Module 0, I2C5 Mux @0x73
    # Creates virtual Buses 24-27
    echo pca9546 0x73 > /sys/class/i2c-dev/i2c-5/device/new_device
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Failed to bind IO Expander 5-0073 to pca9546 driver"
    else
        echo -2 > /sys/bus/i2c/drivers/pca954x/5-0073/idle_state
        echo "IO Expander 5-0073 has been bound to /sys/bus/i2c/drivers/pca954x"
    fi


    # Module 1, I2C5 Mux @0x75
    # Creates virtual Buses 28-31
    echo pca9546 0x75 > /sys/class/i2c-dev/i2c-5/device/new_device
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Failed to bind IO Expander 5-0075 to pca9546 driver"
    else
        echo -2 > /sys/bus/i2c/drivers/pca954x/5-0075/idle_state
        echo "IO Expander 5-0075 has been bound to /sys/bus/i2c/drivers/pca954x"
    fi
    # Module 1, I2C5 Mux @0x76
    # Creates virtual Buses 32-35
    echo pca9546 0x76 > /sys/class/i2c-dev/i2c-5/device/new_device
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Failed to bind IO Expander 5-0076 to pca9546 driver"
    else
        echo -2 > /sys/bus/i2c/drivers/pca954x/5-0076/idle_state
        echo "IO Expander 5-0076 has been bound to /sys/bus/i2c/drivers/pca954x"
    fi
    # Module 1, I2C5 Mux @0x77
    # Creates virtual Buses 36-37
    echo pca9546 0x77 > /sys/class/i2c-dev/i2c-5/device/new_device
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Failed to bind IO Expander 5-0077 to pca9546 driver"
    else
        echo -2 > /sys/bus/i2c/drivers/pca954x/5-0077/idle_state
        echo "IO Expander 5-0077 has been bound to /sys/bus/i2c/drivers/pca954x"
    fi

    return 0

}



#######################################
# Print BMC Boot Banner over UART/serial
#
# ARGUMENTS:
#   None
# RETURN:
#   None
bmc_boot_banner()
{
    stty -F /dev/ttyS0 115200
    echo "" > /dev/ttyS0
    echo "" > /dev/ttyS0
    echo "$(cat /usr/bin/banner_art.txt)" > /dev/ttyS0
    echo "" > /dev/ttyS0
    echo "+---------------------+" > /dev/ttyS0
    echo "| VERSION INFORMATION |" > /dev/ttyS0
    echo "+---------------------+" > /dev/ttyS0
    echo "$(cat /etc/os-release)" > /dev/ttyS0
    echo "" > /dev/ttyS0
    echo "+---------------------+" > /dev/ttyS0
    echo "| NETWORK INFORMATION |" > /dev/ttyS0
    echo "+---------------------+" > /dev/ttyS0
    echo "$(ip a)" > /dev/ttyS0
    echo "" > /dev/ttyS0
    echo "" > /dev/ttyS0
}

#######################################
# Manually bind GPIO expander driver
#
# On AC Cycle, the BMC will boot and the carrier board
# will not be powered on (STBY power). The kernel will not detect
# the IO Expander and therefore will not bind a driver to it.
#
# This function enables the ability to manually bind the driver
# to the IO Expander.
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Always
bind_gpio_expanders()
{

    # BMC IO Expander @0x21
    if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "4-0021"` ]]; then
        echo "Could not find 4-0021, manually binding PCA driver"
        echo "4-0021" > /sys/bus/i2c/drivers/pca953x/bind
        rc=$?
        if [[ $rc -ne 0 ]]; then
            echo "[ERROR] Failed to bind IO Expander 4-0021 to pca953x driver"
        else
            echo "IO Expander 4-0021 has been bound to /sys/bus/i2c/drivers/pca953x"
        fi
    fi

    # UT 3.0 IO Expander @0x21
    if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "6-0021"` ]]; then
        echo "Could not find 6-0021 (UT 3.0), manually binding PCA driver"
        echo "6-0021" > /sys/bus/i2c/drivers/pca953x/bind
        rc=$?
        if [[ $rc -ne 0 ]]; then
            echo "[ERROR] Failed to bind IO Expander 6-0021 to pca953x driver"
        else
            echo "IO Expander 6-0021 (UT 3.0) has been bound to /sys/bus/i2c/drivers/pca953x"
        fi
    fi

    # Module 0, Expander @0x20
    if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "9-0020"` ]]; then 
        echo "Could not find 9-0020, manually binding PCA driver"
        echo "9-0020" > /sys/bus/i2c/drivers/pca953x/bind
        rc=$?
        if [[ $rc -ne 0 ]]; then
            echo "[ERROR] Failed to bind IO Expander 9-0020 to pca953x driver"
        else
            echo "IO Expander 9-0020 has been bound to /sys/bus/i2c/drivers/pca953x"
        fi
    fi

    # Module 1, Expander @0x21
    if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "9-0021"` ]]; then 
        echo "Could not find 9-0021, manually binding PCA driver"
        echo "9-0021" > /sys/bus/i2c/drivers/pca953x/bind
        rc=$?
        if [[ $rc -ne 0 ]]; then
            echo "[ERROR] Failed to bind IO Expander 9-0021 to pca953x driver"
        else
            echo "IO Expander 9-0021 has been bound to /sys/bus/i2c/drivers/pca953x"
        fi
    fi

    # UT 3.0 IO Expander @0x26
    if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "9-0026"` ]]; then
        echo "Could not find 9-0026 (UT 3.0), manually binding PCA driver"
        echo "9-0026" > /sys/bus/i2c/drivers/pca953x/bind
        rc=$?
        if [[ $rc -ne 0 ]]; then
            echo "[ERROR] Failed to bind IO Expander 9-0026 to pca953x driver"
        else
            echo "IO Expander 9-0026 (UT 3.0) has been bound to /sys/bus/i2c/drivers/pca953x"
        fi
    fi

    # HMC IO Expander @0x27
    if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "9-0027"` ]]; then 
        echo "Could not find 9-0027, manually binding PCA driver"
        echo "9-0027" > /sys/bus/i2c/drivers/pca953x/bind
        rc=$?
        if [[ $rc -ne 0 ]]; then
            echo "[ERROR] Failed to bind IO Expander 9-0027 to pca953x driver"
        else
            echo "IO Expander 9-0027 has been bound to /sys/bus/i2c/drivers/pca953x"
        fi
    fi

    # Module 0, IO Board IO Expander
    # I2C MUX, Bus5 @0x72
    # MUX Channel-1, Virtual I2C21 @0x20
    if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "21-0020"` ]]; then
        echo "Could not find 21-0020, manually binding PCA driver"
        # Confirm virtual I2C bus 21 exists
        if [[ ! -z `ls /sys/bus/i2c/devices/ | grep "i2c-21"` ]]; then
            # I2C-21 exists, attempt to bind driver to IO expander
            # Use new_device interface because this does not require a DTS entry
            echo pca9555 0x20 > /sys/class/i2c-dev/i2c-21/device/new_device
            rc=$?
            if [[ $rc -ne 0 ]]; then
                echo "[ERROR] Failed to bind IO Expander 21-0020 to pca953x driver"
            else
                echo "IO Expander 21-0020 has been bound to /sys/bus/i2c/drivers/pca953x"
            fi
        else
            echo "[ERROR] Bus I2C-21 does not exist. Can not bind IO expander driver."
        fi
    fi

    # Module 1, IO Board IO Expander
    # I2C MUX, Bus5 @0x76
    # MUX Channel-1, Virtual I2C33 @0x21
    if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "33-0021"` ]]; then
        echo "Could not find 33-0021, manually binding PCA driver"
        # Confirm virtual I2C bus 33 exists
        if [[ ! -z `ls /sys/bus/i2c/devices/ | grep "i2c-33"` ]]; then
            # I2C-33 exists, attempt to bind driver to IO expander
            # Use new_device interface because this does not require a DTS entry
            echo pca9555 0x21 > /sys/class/i2c-dev/i2c-33/device/new_device
            rc=$?
            if [[ $rc -ne 0 ]]; then
                echo "[ERROR] Failed to bind IO Expander 33-0021 to pca953x driver"
            else
                echo "IO Expander 33-0021 has been bound to /sys/bus/i2c/drivers/pca953x"
            fi
        else
            echo "[ERROR] Bus I2C-33 does not exist. Can not bind IO expander driver."
        fi
    fi

    return 0
}

########### MAIN ############

echo "Host BMC Post-boot Configuration"

# Reset manual control of PCI_MUX_SEL-O to default state
if [[ -f "$MANUAL_PCI_MUX_SEL_FILE" ]]; then
    echo "Disable manual control of PCI_MUX_SEL-O"
    rm $MANUAL_PCI_MUX_SEL_FILE
fi

# TODO: Audit if these should be exported through sysfs
#
# Export GPOs (outputs only) that need to be shared across processes
# Careful - only set direction if needed (otherwise pin assumes default level)
#  182
# RUN_POWER_EN-O
echo ${sysfs_run_power} > /sys/class/gpio/export
pindir=`cat /sys/class/gpio/gpio${sysfs_run_power}/direction`
if [ $pindir != "out" ]; then
    echo "out" > /sys/class/gpio/gpio${sysfs_run_power}/direction
fi

# Initialize GPIO out state
# Before STBY power is on and HMC is not ready
gpival=$(gpioget `gpiofind "HMC_READY-I"`)
if [[ $gpival -eq 0 ]]; then
    bmc_set_initial_gpio_out
fi

#
# Write STBY_POWER_EN=1 to turn on the standby power to the HMC and FPGA and let it boot
#
set_gpio_level "STBY_POWER_EN-O" $HIGH

wait_standby_pwr
rc=$?
if [[ $rc -ne 0 ]]; then
    err_msg="wait_standby_pwr failed"
    echo $err_msg
    phosphor_log "$err_msg" $sevErr
    exit 1
fi

#
# Bind I2C MUX drivers after STBY_POWER
#
bind_i2c_muxes

#
# Bind IO Expander driver after STBY_POWER
# IO Expander requires STBY_POWER 
#
bind_gpio_expanders

set_gpio_level "USB_HUB_RESET_L-O" $LOW
sleep 1
set_gpio_level "USB_HUB_RESET_L-O" $HIGH

#
# Write HMC_PGOOD-O=1 to enable PCIe discovery of FPGA
#
set_gpio_level "HMC_PGOOD-O" $HIGH

#Discover number of modules connected
discover_modules

#
# Write SGPIO_BMC_EN-O=1 to correctly set mux to send SGPIO signals to FPGA
#
set_gpio_level "SGPIO_BMC_EN-O" $HIGH

# Set BMC_EROT_FPGA_SPI_MUX_SEL-O = 1 to enable FPGA to access its EROT
set_gpio_level "BMC_EROT_FPGA_SPI_MUX_SEL-O" $HIGH

# Initialize GPIO out state
# after STBY power is on and HMC is not ready
gpival=$(gpioget `gpiofind "HMC_READY-I"`)
if [[ $gpival -eq 0 ]]; then
    bmc_set_stby_pg_gpio_out
fi

#
# Release FPGA EROT from reset
#
set_gpio_level "EROT_FPGA_RST_L-O" $HIGH
set_gpio_level "SEC_EROT_FPGA_RST_L-O" $HIGH

#
# Release HMC EROT from reset
#
set_gpio_level "HMC_EROT_RST_L-O" $HIGH

#
# Release HMC from reset
#
set_gpio_level "HMC_RESET_L-O" $HIGH

#
# Wait for HMC to signal ready
#
wait_gpio_assert  "HMC_READY-I"
rc=$?
if [[ $rc -ne 0 ]]; then
    exit 1
fi

# Fix hmcusb0 not showing up after AC cycle
echo 1e6a3000.usb > /sys/bus/platform/drivers/ehci-platform/unbind
echo 1e6a3000.usb > /sys/bus/platform/drivers/ehci-platform/bind

wait_gpio_assert  "FPGA_READY_BMC-I"
rc=$?
if [[ $rc -ne 0 ]]; then
    exit 1
fi

# Bind all EEPROM drivers for EEPROMs powered by STBY_POWER
create_eeprom_devices

# Print BMC Boot Banner
bmc_boot_banner

# Enable UART3 -> UART1 routing. 
# Note: 1->3 will not work, SOL will function normally
# IO board supports both UART1 and UART3, but UART1 is not in use 
# Uncomment the below line if UART1 is required in the future
# echo -n "io3" > /sys/bus/platform/drivers/aspeed-uart-routing/*.uart-routing/io1 

# Confirm
check_rofs
rc=$?
if [[ $rc -ne 0 ]]; then
    exit 1
fi

# Confirm filesystems are mounted
check_rw_filesystems
rc=$?
if [[ $rc -ne 0 ]]; then
    exit 1
fi

# Module Temp Sensor Setting.
# Bringup: remove for now
#set_module_temp_sensor_threshold.sh

#
# Assert BMC_READY-O=1
#
set_bmc_ready
rc=$?
if [[ $rc -ne 0 ]]; then
    exit 1
fi

phosphor_log "bmc_ready.sh completed" $sevNot

#
# Exit without error to prevent systemd from restarting it
#
exit 0
