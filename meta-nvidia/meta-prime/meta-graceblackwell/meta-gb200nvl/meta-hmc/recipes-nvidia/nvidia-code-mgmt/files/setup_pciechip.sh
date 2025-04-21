#!/bin/sh

if [[ -z `ls /sys/bus/i2c/drivers/pca953x | grep "1-0024"` ]]; then
    echo "Gpio expander not present. Ensure FPGA is alive."
    exit 1
fi

power_state=$(busctl get-property xyz.openbmc_project.State.Chassis /xyz/openbmc_project/state/chassis0 xyz.openbmc_project.State.Chassis CurrentPowerState)

if [[ "$power_state" == "s \"xyz.openbmc_project.State.Chassis.PowerState.On\"" ]]; then
    gpioset `gpiofind "HMC_SPI_MUX_SEL_1V8"`=1
    gpioset `gpiofind "BRDG_MUX_SEL_IOX"`=0
    gpioset `gpiofind "MUX_SEL_FPGA_BRDG_1V8"`=1
    sleep 1
    #disable mtd driver just in case
    echo "1e630000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/unbind
    sleep 1
    #enable spi driver
    echo "1e630000.spiraw" > /sys/bus/platform/drivers/fmc_spi/bind
    sleep 1
    set-spi-wp -d /dev/spidev2.0 -a deassert
    #if it is running fw update fail
    if [ $? -eq 255 ] && [ "$1" -eq 1 ]; then
        #wp is asserted
        set-spi-wp -d /dev/spidev2.0 -a assert
        exit 1
    fi
    echo "1e630000.spiraw" > /sys/bus/platform/drivers/fmc_spi/unbind
    sleep 1

    echo "1e630000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/bind
    exit 0
else
    echo "Platform must be ON to update pciechip config"
    exit 1
fi
