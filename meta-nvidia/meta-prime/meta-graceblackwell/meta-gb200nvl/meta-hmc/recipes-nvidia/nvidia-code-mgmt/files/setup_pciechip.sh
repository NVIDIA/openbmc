#!/bin/sh

wait_for_pciechip_mtd_release() {
    mtddev=$(grep -xl "pciechip_config" /sys/class/mtd/*/name | sed -e 's|.*/||' -e 's|/name||')
    devpath="/dev/$mtddev"

    if [ -z "$mtddev" ]; then
        echo "No pciechip MTD device found; assuming safe to proceed."
        return 0
    fi

    for i in {1..10}; do
        if ! lsof "$devpath" >/dev/null 2>&1; then
            return 0
        fi
        echo "Waiting for $devpath to be released..."
        sleep 1
    done

    echo "Timeout waiting for $devpath to close"
    return 1
}

if [[ -z $(ls /sys/bus/i2c/drivers/pca953x | grep "1-0024") ]]; then
    echo "GPIO expander not present. Ensure FPGA is alive."
    exit 1
fi

power_state=$(busctl get-property xyz.openbmc_project.State.Chassis \
    /xyz/openbmc_project/state/chassis0 \
    xyz.openbmc_project.State.Chassis CurrentPowerState)

if [[ "$power_state" == "s \"xyz.openbmc_project.State.Chassis.PowerState.On\"" ]]; then
    gpioset $(gpiofind "HMC_SPI_MUX_SEL_1V8")=1
    gpioset $(gpiofind "BRDG_MUX_SEL_IOX")=0
    gpioset $(gpiofind "MUX_SEL_FPGA_BRDG_1V8")=1
    sleep 1

    echo "1e630000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/unbind
    udevadm settle
    sleep 1

    echo "1e630000.spiraw" > /sys/bus/platform/drivers/fmc_spi/bind
    udevadm settle
    sleep 1

    set-spi-wp -d /dev/spidev2.0 -a deassert
    if [ $? -eq 255 ] && [ "$1" -eq 1 ]; then
        set-spi-wp -d /dev/spidev2.0 -a assert
        exit 1
    fi

    echo "1e630000.spiraw" > /sys/bus/platform/drivers/fmc_spi/unbind
    udevadm settle
    sleep 1

    wait_for_pciechip_mtd_release
    echo "1e630000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/bind
    udevadm settle
    exit 0
else
    echo "Platform must be ON to update pciechip config"
    exit 255
fi

