#!/bin/sh

# Check for the presence of the secondary module
presence=$(busctl get-property xyz.openbmc_project.presence-detect /xyz/openbmc_project/inventory/system/cable/HGX_ProcessorModule_Management_0 xyz.openbmc_project.Inventory.Item Present)

if [ "$presence" != "b true" ]; then
    echo "[ERROR] Secondary module cable not detected. Exiting..."
    exit 1
fi


if [ "$1" == "notready" ]; then

    echo "FPGA1 is not ready. Attempting to toggle the FPGA1 SPI MUX to FPGA0."

    if i2cdetect -y 2 | grep -q "24"; then
        # toggle the FPGA1 SPI MUX SEL to let FPGA0 connect FPGA1 ERoT via SPI
        echo "FPGA1 I2C device 0x24 was found. Toggling the SPI MUX."
        i2ctransfer -y 2 w2@0x24 0x02 0xFE
        i2ctransfer -y 2 w2@0x24 0x06 0xFE
    else
        echo "[ERROR] FPGA1 I2C device 0x24 not found on i2c-2 bus. Unable to toggle SPI MUX"
        exit 1
    fi

    echo "Resetting the FPGA0..."

    # hold FPGA0 reset pin
    gpioset `gpiofind FPGA_RST_L-O`=0
    sleep 3
    # release FPGA0 reset pin
    gpioset `gpiofind FPGA_RST_L-O`=1
    sleep 3

    # restart the MCTP USB control to re-discovery
    echo "Restarting the mctp-usb-ctrl..."
    systemctl restart mctp-usb-ctrl

    exit 0

elif [ "$1" == "ready" ]; then
    
    if i2cdetect -y 2 | grep -q "24"; then
        # toggle the SPI MUX SEL to disconnect the SPI path between FPGA0 and FPGA1 ERoT
        echo "FPGA1 I2C device 0x24 was found. Resetting FPGA1 SPI MUX."
        i2ctransfer -y 2 w2@0x24 0x02 0xFF
        i2ctransfer -y 2 w2@0x24 0x06 0xFF
        exit 0
    else
        echo "Warning: I2C device 0x24 not found on i2c-2 bus. Skipping SPI MUX reset."
        exit 0
    fi
else
    echo "Invalid argument. Please use 'notready' or 'ready'."
    exit 1
fi
