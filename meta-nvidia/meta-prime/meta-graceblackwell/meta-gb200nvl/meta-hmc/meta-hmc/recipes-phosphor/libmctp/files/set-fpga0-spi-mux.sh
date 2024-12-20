
#!/bin/bash

set -e

# FPGA SPI MUX select pin
GPIO_NAME="HMC_SPI_MUX_SEL_1V8"

# check if pin exist
gpio_chip_num=$(gpiofind "$GPIO_NAME")
if [ -z "$gpio_chip_num" ]; then
    echo "Error: Failed to find GPIO $GPIO_NAME"
    exit 1
fi
echo "Found $GPIO_NAME ($gpio_chip_num)"

# Switch SPI MUX
if [ "$1" == "HMC" ]; then
    echo "Switching FPGA0 ERoT to HMC..."
    gpioset $gpio_chip_num=0
elif [ "$1" == "FPGA0" ]; then
    echo "Switching FPGA0 ERoT to FPGA0..."
    gpioset $gpio_chip_num=1
else
    echo "Usage: $0 {HMC|FPGA0}"
    exit 1
fi