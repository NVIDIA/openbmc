#!/bin/bash
source /etc/default/nvidia_event_logging.sh

WAIT_FPGA_READY_TIMEOUT_SECS=120
WAIT_FPGA_READY_INTERVAL_SECS=5

HIGH=1
LOW=0

# GPIO Line names
# NOTE: Get GPIO line names from nvidia-gb200nvl-hmc-core.dtsi
FPGA_RST_NAME="FPGA_RST_L-O"
FPGA_READY_NAME="FPGA0_READY-I"
HMC_GLOBAL_WP_NAME="HMC_GLOBAL_WP-I"

# Inherit gpio_pins
source /usr/bin/gpio_pins.sh

EROT_FPGA_RST_L=$GPIO_C6
HMC_READY=$GPIO_D1
EROT_FPGA_RECOVERY_L=$GPIO_D2
HMC_GLOBAL_WP=$GPIO_I6
FPGA_RST_L=$GPIO_M2

# Release FPGA from reset
set_fpga_rst()
{
    echo "Set FPGA reset, set ${FPGA_RST_NAME} to 1"
    gpioset `gpiofind "FPGA_RST_L-O"`=1
}

#######################################
# Execute required steps to release FPGA from reset
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Always
execute_fpga_power_sequence()
{

    # Release FPGA from reset
    set_fpga_rst $HIGH

    return 0

}