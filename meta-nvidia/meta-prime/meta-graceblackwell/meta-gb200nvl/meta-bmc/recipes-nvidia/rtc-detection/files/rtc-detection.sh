#!/bin/bash

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

I2C_BUS=4
I2C_ADDR=0x6f

#Detect the rtc device by reading a vendor register
DEVICE_ID=$(i2cget -f -y $I2C_BUS $I2C_ADDR 0x10)

if [[ $DEVICE_ID == "0x5c" ]]; then
        echo "NCT3018Y rtc device detected"

        echo nct3018y 0x6f > /sys/class/i2c-dev/i2c-4/device/new_device
	rc=$?
	if [[ $rc -ne 0 ]]; then
            phosphor_log "NCT3018Y rtc driver not bind" $sevErr
	fi
	
elif [[ $DEVICE_ID == "0x4e" ]]; then
        echo "PCF8503a rtc device detected"

	echo pcf85053a 0x6f > /sys/class/i2c-dev/i2c-4/device/new_device
	rc=$?
	if [[ $rc -ne 0 ]]; then
            phosphor_log "PCF8503A rtc driver not bind" $sevErr
	fi
else
        echo "Unknown device at address $I2C_ADDR"
            exit 1
fi
