#!/bin/sh
source /usr/bin/mc_lib.sh

if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "9-0074"` ]]; then
    echo "Gpio expander not present. Ensure FPGA is alive."
    exit 1
fi

gpio_value=`get_run_power_pg`
if [ "$gpio_value" -eq 1 ]; then
    echo "Setting CPLD_JTAG_MUX_SEL = 1"
    gpioset `gpiofind CPLD_JTAG_MUX_SEL`=1
    sleep 1
    exit 0
else
    echo "RUN_POWER must be ON to update CPLD"
    exit 1
fi