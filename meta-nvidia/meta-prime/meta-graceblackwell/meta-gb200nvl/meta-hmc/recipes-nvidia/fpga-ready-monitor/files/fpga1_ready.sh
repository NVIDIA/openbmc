#!/bin/sh
source /etc/default/nvidia_event_logging.sh

# Check for the presence of the secondary module
presence=$(busctl get-property xyz.openbmc_project.presence-detect /xyz/openbmc_project/inventory/system/cable/HGX_ProcessorModule_Management_0 xyz.openbmc_project.Inventory.Item Present)

if [ "$presence" != "b true" ]; then
    echo "[ERROR] Secondary module cable not detected. Exiting..."
    exit 1
fi

if [ "$1" == "notready" ]; then

    echo "FPGA1 is not ready. Attempting to toggle the FPGA1 SPI MUX to FPGA0 for FW recovery."
    echo "Checking if FPGA0 supports MCTP re-enumeration..."
    support_re_enum=$(i2ctransfer -y 1 w2@0x11 0xd0 0x01 r1)

    # Check if i2ctransfer command itself was successful
    if [ $? -ne 0 ]; then
        echo "[ERROR] FPGA1 FW recovery: Failed to read FPGA0 0x1D0 register."
        phosphor_log "FPGA1 FW recovery: Failed to read FPGA0 0x1D0 register." $sevErr
        exit 1
    fi

    # Check if the support_re_enum register is set to 0x01
    if [ "$support_re_enum"  != "0x01" ]; then
        echo "[ERROR] FPGA1 FW recovery: Current FPGA does not support MCTP re-enumeration. Please ensure the FPGA FW version >= 1.42"
        phosphor_log "FPGA1 FW recovery: Current FPGA does not support MCTP re-enumeration. Please ensure the FPGA FW version >= 1.42" $sevErr
        exit 1
    fi

    if i2cdetect -y 2 | grep -q "24"; then
        # toggle the FPGA1 SPI MUX SEL to let FPGA0 connect FPGA1 ERoT via SPI
        echo "GPIO EXP device 0x24 was found. Toggling the SPI MUX."
        i2ctransfer -y 2 w2@0x24 0x02 0xFE
        i2ctransfer -y 2 w2@0x24 0x06 0xFE
    else
        echo "[ERROR] GPIO EXP device 0x24 not found on i2c-2 bus. Unable to toggle SPI MUX"
        exit 1
    fi

    # Wait for MCTP USB control service to be available
    echo "Waiting for MCTP USB control service available..."
    while true; do
        if busctl tree xyz.openbmc_project.MCTP.Control.USB | grep -q "/xyz/openbmc_project/mctp/USB"; then
            echo "MCTP USB control service found."
            break
        else
            echo "MCTP USB control service not yet available. Retrying in 1 second..."
            sleep 5
        fi
    done

    max_retries=5
    for i in $(seq 1 $max_retries)
    do
        echo "Attempting MCTP re-enumeration (Attempt ${i}/${max_retries})..."
        i2ctransfer -y 1 w3@0x11 0xd1 0x01 0x1
        sleep 1
        # it takes ~10 seconds for the FPGA0 to re-enumerate MCTP endpoint based on the experimental data
        i2ctransfer -y 1 w3@0x11 0xd1 0x01 0x0
        sleep 10

        echo "Checking if FPGA1 (EID 14) is present..."
        # Check if the EID 14 is present
        if busctl tree xyz.openbmc_project.MCTP.Control.USB | grep -q "/xyz/openbmc_project/mctp/0/14"; then
            echo "FPGA1 (EID 14) found!"
            exit 0
        fi

        # If not yet at max retries, retry
        if [ "$i" -lt "$max_retries" ]; then
            echo "FPGA1 (EID 14) not found. Retrying ... (Attempt ${i}/${max_retries})"
        else
            # Reached max retries and still not found
            echo "[ERROR] FPGA1 FW recovery: FPGA1 (EID 14) not found after $max_retries attempts."
            phosphor_log "FPGA1 FW recovery: Failed to find FPGA1 (EID 14) after re-enumeration." $sevErr
            exit 1
        fi
    done

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
