#!/bin/bash

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

# Sometimes after an AC power cycle, standby power isn't on when we try to bind the fan drivers
# This section below will ensure the fan controller drivers get bound
Count=0
until [[ $Count -gt 15 ]]
do
    if [ `i2cdetect -y 6 0x20 0x20 |grep UU | wc -l` == 0 ]; then
        echo "max31790 driver not bound..."
        if [ -e /sys/bus/i2c/drivers/max31790/bind ]; then
            echo "Binding"
            echo 6-0020 > /sys/bus/i2c/drivers/max31790/bind
            echo 6-0023 > /sys/bus/i2c/drivers/max31790/bind
            echo 6-002c > /sys/bus/i2c/drivers/max31790/bind
            echo 6-002f > /sys/bus/i2c/drivers/max31790/bind
            if [ $? == 0 ]; then
                break
            else
                echo "Bind failed..."
            fi
	    else
	        echo "Path not present"
	    fi
        sleep 2
    else
        break
    fi
    ((Count++))
done

# Convert PWM5 and PWM6 to Tach Input (needed to enable certain fans)
i2cset -f -y 6 0x20 0x6 0x9
i2cset -f -y 6 0x20 0x7 0x9

# Convert PWM5 and PWM6 to Tach Input (needed to enable certain fans)
i2cset -f -y 6 0x2c 0x6 0x9
i2cset -f -y 6 0x2c 0x7 0x9

# TACH input enable for fans @ addr 0x20
i2cset -f -y 6 0x20 0x2 0x48
i2cset -f -y 6 0x20 0x3 0x48
i2cset -f -y 6 0x20 0x4 0x48
i2cset -f -y 6 0x20 0x5 0x48

# TACH input enable for fans @ addr 0x23
i2cset -f -y 6 0x23 0x2 0x48
i2cset -f -y 6 0x23 0x3 0x48

# TACH input enable for fans @ addr 0x2c
i2cset -f -y 6 0x2c 0x2 0x48
i2cset -f -y 6 0x2c 0x3 0x48
i2cset -f -y 6 0x2c 0x4 0x48
i2cset -f -y 6 0x2c 0x5 0x48

# TACH input enable for fans @ addr 0x2f
i2cset -f -y 6 0x2f 0x2 0x48
i2cset -f -y 6 0x2f 0x3 0x48

# Apply Tach configuration (rebind drivers)
echo 6-0020 > /sys/bus/i2c/drivers/max31790/unbind
echo 6-0023 > /sys/bus/i2c/drivers/max31790/unbind
echo 6-002c > /sys/bus/i2c/drivers/max31790/unbind
echo 6-002f > /sys/bus/i2c/drivers/max31790/unbind
sleep 0.5
echo 6-0020 > /sys/bus/i2c/drivers/max31790/bind
echo 6-0023 > /sys/bus/i2c/drivers/max31790/bind
echo 6-002c > /sys/bus/i2c/drivers/max31790/bind
echo 6-002f > /sys/bus/i2c/drivers/max31790/bind

# Tray Detection
# Wait until Entity Manager has started putting configs on dbus
Count=0
until [[ $Count -gt 30 ]]
do
    if [ `busctl tree xyz.openbmc_project.EntityManager |grep /xyz/openbmc_project/inventory/system/chassis/Chassis_0/Chassis_0_FAN | wc -l` == 0 ]; then
        sleep 1
    else
        break
    fi
    ((Count++))
done

# A detected tray will put the fans on dbus. If a tray wasn't detected over all this time, then alert the user and set the fans to 80%
if [ $Count -gt 30 ]; then
    echo "Tray detection failed. CBC FRU EEPROM missing or unprogrammed. Running all fans at 80%."
    phosphor_log "Tray detection failed. PDB FRU EEPROM missing, unprogrammed, or not recognized. Running all fans at 80%." $sevErr
    fan-manual-speed.sh 80
fi
