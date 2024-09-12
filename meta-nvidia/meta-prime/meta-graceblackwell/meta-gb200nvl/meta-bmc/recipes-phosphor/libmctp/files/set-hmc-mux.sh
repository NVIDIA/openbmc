#!/bin/bash

set -e

# HMC SPI MUX select pin
GPIO_NAME="HMC_EROT_SPI_MUX_SEL-O"

# check if pin exist
gpio_chip_num=$(gpiofind "$GPIO_NAME")
if [ -z "$gpio_chip_num" ]; then
    echo "Error: Failed to find GPIO $GPIO_NAME"
    exit 1
fi
echo "Found $GPIO_NAME ($gpio_chip_num)"

# Switch SPI MUX
if [ "$1" == "BMC" ]; then
    echo "Switching HMC ERoT to BMC..."
    gpioset $gpio_chip_num=0
elif [ "$1" == "FPGA" ]; then
    echo "Switching HMC ERoT to FPGA..."
    gpioset $gpio_chip_num=1
else
    echo "Usage: $0 {BMC|FPGA}"
    exit 1
fi
