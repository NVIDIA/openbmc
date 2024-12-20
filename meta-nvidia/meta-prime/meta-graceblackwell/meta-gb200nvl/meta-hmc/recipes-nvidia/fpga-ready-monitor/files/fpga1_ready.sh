#!/bin/sh

# Check for the presence of the secondary module
presence=$(busctl get-property xyz.openbmc_project.presence-detect /xyz/openbmc_project/inventory/system/cable/HGX_ProcessorModule_Management_0 xyz.openbmc_project.Inventory.Item Present)

if [ "$presence" != "b true" ]; then
    echo "Secondary module does not exist. Exiting the script..."
    exit 1
fi

if [ "$1" == "notready" ]; then
    # toggle the FPGA1 SPI MUX SEL to let FPGA0 connect FPGA1 ERoT via SPI
    echo "FPGA1 is not ready. Toggling the SPI MUX to FPGA0..."
    i2ctransfer -y 2 w2@0x24 0x02 0xFE
    i2ctransfer -y 2 w2@0x24 0x06 0xFE

    # hold FPGA0 reset pin
    echo "Resetting the FPGA0..."
    gpioset `gpiofind FPGA_RST_L-O`=0

    # check if FPGA0 is not ready
    for i in {1..60}; do
        if busctl tree com.Nvidia.FWStatus | grep -q "/xyz/openbmc_project/software/HGX_FW_FPGA_0"; then
            echo "HGX_FW_FPGA_0 is off. Releasing FPGA0 reset pin..."
            break
        fi
        if [ $i -eq 60 ]; then
            echo "Timeout waiting for HGX_FW_FPGA_0 to publish. Exiting..."
            exit 1
        fi
        sleep 1
    done

    # release FPGA0 reset pin
    gpioset `gpiofind FPGA_RST_L-O`=1

    # check if FPGA0 is ready
    for i in {1..60}; do
        if ! busctl tree com.Nvidia.FWStatus | grep -q "/xyz/openbmc_project/software/HGX_FW_FPGA_0"; then
            echo "HGX_FW_FPGA_0 is on."
            break
        fi
        if [ $i -eq 60 ]; then
            echo "Timeout waiting for HGX_FW_FPGA_0 to disappear. Exiting..."
            exit 1
        fi
        sleep 1
    done

    # restart the MCTP USB control to re-discovery
    echo "Restarting the mctp-usb-ctrl..."
    systemctl restart mctp-usb-ctrl

elif [ "$1" == "ready" ]; then
    # toggle the SPI MUX SEL to disconnect the SPI path between FPGA0 and FPGA1 ERoT
    echo "FPGA1 is ready. Resetting the SPI MUX..."
    i2ctransfer -y 2 w2@0x24 0x02 0xFF
    i2ctransfer -y 2 w2@0x24 0x06 0xFF

else
    echo "Invalid argument. Please use 'notready' or 'ready'."
fi