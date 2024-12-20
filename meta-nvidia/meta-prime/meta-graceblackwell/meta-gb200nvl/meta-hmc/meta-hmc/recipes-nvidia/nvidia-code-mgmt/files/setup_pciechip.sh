#!/bin/sh

if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "1-0024"` ]]; then
    echo "Gpio expander not present. Ensure FPGA is alive."
    exit 1
fi

power_state=$(busctl get-property xyz.openbmc_project.State.Chassis /xyz/openbmc_project/state/chassis0 xyz.openbmc_project.State.Chassis CurrentPowerState)

if [[ "$power_state" == "s \"xyz.openbmc_project.State.Chassis.PowerState.On\"" ]]; then
    if [ -e "/sys/bus/platform/drivers/fmc_spi/1e630000.spiraw" ]; then
         echo "1e630000.spiraw" > /sys/bus/platform/drivers/fmc_spi/unbind
    fi
    echo "1e630000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/unbind
    sleep 1
    gpioset `gpiofind "HMC_SPI_MUX_SEL_1V8"`=1
    gpioset `gpiofind "BRDG_MUX_SEL_IOX"`=0
    gpioset `gpiofind "MUX_SEL_FPGA_BRDG_1V8"`=1
    sleep 1
    echo "1e630000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/bind
    exit 0
else
    echo "Platform must be ON to update pciechip config"
    exit 1
fi
