#!/bin/bash

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

Count=0
until [[ $Count -gt 15 ]]
do
    echo "Checking mux driver ($Count)..."
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

#Convert PWM5 and PWM6 to Tach Input
i2cset -f -y 6 0x20 0x6 0x9
i2cset -f -y 6 0x20 0x7 0x9

#Convert PWM5 and PWM6 to Tach Input
i2cset -f -y 6 0x2c 0x6 0x9
i2cset -f -y 6 0x2c 0x7 0x9

#Apply Tach configuration
echo 6-0020 > /sys/bus/i2c/drivers/max31790/unbind
echo 6-0023 > /sys/bus/i2c/drivers/max31790/unbind
echo 6-002c > /sys/bus/i2c/drivers/max31790/unbind
echo 6-002f > /sys/bus/i2c/drivers/max31790/unbind
sleep 0.5
echo 6-0020 > /sys/bus/i2c/drivers/max31790/bind
echo 6-0023 > /sys/bus/i2c/drivers/max31790/bind
echo 6-002c > /sys/bus/i2c/drivers/max31790/bind
echo 6-002f > /sys/bus/i2c/drivers/max31790/bind