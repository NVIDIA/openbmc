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
            echo "Binding the fan controller drivers"
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

echo "Enabling the fan controller watchdog timers"
# Read the current value of the registers
controller1=$(i2cget -y -f 6 0x20 0x0)
controller2=$(i2cget -y -f 6 0x23 0x0)
controller3=$(i2cget -y -f 6 0x2c 0x0)
controller4=$(i2cget -y -f 6 0x2f 0x0)
# Use bitwise OR to set watchdog timer to 10s
controller1=$((controller1 | 0x04))
controller2=$((controller2 | 0x04))
controller3=$((controller3 | 0x04))
controller4=$((controller4 | 0x04))
# Write the new value back to the register
i2cset -y -f 6 0x20 0x0 $controller1
i2cset -y -f 6 0x23 0x0 $controller2
i2cset -y -f 6 0x2c 0x0 $controller3
i2cset -y -f 6 0x2f 0x0 $controller4

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
until [[ $Count -gt 60 ]]
do
    if [ `busctl tree xyz.openbmc_project.EntityManager |grep /xyz/openbmc_project/inventory/system/chassis/Chassis_0/Chassis_0_FAN | wc -l` == 0 ]; then
        sleep 1
    else
        break
    fi
    ((Count++))
done

# Clear the watchdog status bit
# Read the current value of the registers
controller1=$(i2cget -y -f 6 0x20 0x0)
controller2=$(i2cget -y -f 6 0x23 0x0)
controller3=$(i2cget -y -f 6 0x2c 0x0)
controller4=$(i2cget -y -f 6 0x2f 0x0)
# Use bitwise AND to clear the watchdog status bit
controller1=$((controller1 & 0xfe))
controller2=$((controller2 & 0xfe))
controller3=$((controller3 & 0xfe))
controller4=$((controller4 & 0xfe))
# Write the new value back to the register
i2cset -y -f 6 0x20 0x0 $controller1
i2cset -y -f 6 0x23 0x0 $controller2
i2cset -y -f 6 0x2c 0x0 $controller3
i2cset -y -f 6 0x2f 0x0 $controller4

# A detected tray will put the fans on dbus. If a tray wasn't detected over all this time, then alert the user and set the fans to 100%
if [ $Count -gt 60 ]; then
    echo "Tray detection failed. PDB FRU EEPROM missing, unprogrammed, or not recognized. Running all fans at 100%."
    phosphor_log "Tray detection failed. PDB FRU EEPROM missing, unprogrammed, or not recognized. Running all fans at 100%." $sevErr
    fan-manual-speed.sh 100
fi
