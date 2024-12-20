#!/bin/bash

set -e

# GPIO to toggle the HMC SPI MUX
SPI_MUX_SEL_PIN="HMC_EROT_SPI_MUX_SEL-O"

# GPIO to notify FPGA to re-discover HMC ERoT
MUX_STS="HMC_EROT_MUX_STATUS"

# check if HMC_EROT_SPI_MUX_SEL-O exist
mux_sel_pin=$(gpiofind "$SPI_MUX_SEL_PIN")
if [ -z "$mux_sel_pin" ]; then
    echo "Error: Failed to find GPIO $SPI_MUX_SEL_PIN"
    exit 1
fi

# check if HMC_EROT_MUX_STATUS exist
mux_sts_pin=$(gpiofind "$MUX_STS")
if [ -z "$mux_sts_pin" ]; then
    echo "Error: Failed to find GPIO $MUX_STS"
    exit 1
fi

if [ "$1" == "BMC" ]; then
    echo "Switching HMC ERoT to BMC..."
    # FPGA to drop HMC from its routing table
    gpioset $mux_sts_pin=1
    # switch SPI MUX to BMC
    gpioset $mux_sel_pin=0
elif [ "$1" == "FPGA" ]; then
    echo "Switching HMC ERoT to FPGA..."
    # switch SPI MUX to FPGA
    gpioset $mux_sel_pin=1
    # FPGA to re-enum and send discovery notify to HMC
    gpioset $mux_sts_pin=0
else
    echo "Usage: $0 {BMC|FPGA}"
    exit 1
fi
