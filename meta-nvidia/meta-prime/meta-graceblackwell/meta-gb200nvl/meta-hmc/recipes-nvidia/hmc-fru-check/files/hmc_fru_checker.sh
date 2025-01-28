#!/bin/bash

#
# I2C Bus 3 collisions rarely occur once the HMC FRU device probes.
# This is because the BMC Satellite Sensor constantly reads I2C
# direct sensors from HMC I2C Bus 3, which turns the HMC into I2C
# slave mode, causing all other write requests from the HMC to the
# shared I2C bus to be rejected during this period
#

FruDevice="xyz.openbmc_project.FruDevice"
FruDevice_object_path="/xyz/openbmc_project/FruDevice"
ReScan_Bus="3"
Times=0

sleep 3
echo "Scanning for HMC FRU..."

busctl tree $FruDevice | grep P4764 > /dev/null
while [ $? != "0" ] && [ $Times -lt 10 ]
do
        echo "Rescanning HMC FRU bus, attempt ${Times}"
        busctl call $FruDevice $FruDevice_object_path xyz.openbmc_project.FruDeviceManager ReScanBus q $ReScan_Bus
        Times=$((Times + 1))
        sleep 3
        busctl tree $FruDevice | grep P4764 > /dev/null
done
if [ $Times -lt 10 ]
then
	echo "HMC FRU found successfully"
	exit 0
else
        echo "[ERROR] Unable to find the HMC FRU"
	exit 1
fi
