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

#TACH input enable
i2cset -f -y 6 0x20 0x2 0x48
i2cset -f -y 6 0x20 0x3 0x48
i2cset -f -y 6 0x20 0x4 0x48
i2cset -f -y 6 0x20 0x5 0x48
#Convert PWM5 and PWM6 to Tach Input
i2cset -f -y 6 0x20 0x6 0x9
i2cset -f -y 6 0x20 0x7 0x9

i2cset -f -y 6 0x2f 0x2 0x48
i2cset -f -y 6 0x2f 0x3 0x48
i2cset -f -y 6 0x2f 0x4 0x48
i2cset -f -y 6 0x2f 0x5 0x48
#Convert PWM5 and PWM6 to Tach Input
i2cset -f -y 6 0x2f 0x6 0x9
i2cset -f -y 6 0x2f 0x7 0x9

#Set fan controller PWM Frequency Register to 25 kHz
i2cset -f -y 6 0x20 0x1 0xbb
i2cset -f -y 6 0x2f 0x1 0xbb

#Apply Tach configuration
echo 6-0020 > /sys/bus/i2c/drivers/max31790/unbind
echo 6-002f > /sys/bus/i2c/drivers/max31790/unbind
sleep 0.5
echo 6-0020 > /sys/bus/i2c/drivers/max31790/bind
echo 6-002f > /sys/bus/i2c/drivers/max31790/bind

#Set Fan to 100% Duty as Booting Up
mb_fan_1=/sys/devices/platform/ahb/ahb:apb/ahb:apb:bus@1e78a000/1e78a380.i2c-bus/i2c-6/6-0020/hwmon/**/pwm1
mb_fan_2=/sys/devices/platform/ahb/ahb:apb/ahb:apb:bus@1e78a000/1e78a380.i2c-bus/i2c-6/6-0020/hwmon/**/pwm2
mb_fan_3=/sys/devices/platform/ahb/ahb:apb/ahb:apb:bus@1e78a000/1e78a380.i2c-bus/i2c-6/6-0020/hwmon/**/pwm3
mb_fan_4=/sys/devices/platform/ahb/ahb:apb/ahb:apb:bus@1e78a000/1e78a380.i2c-bus/i2c-6/6-0020/hwmon/**/pwm4

gb_fan_1=/sys/devices/platform/ahb/ahb:apb/ahb:apb:bus@1e78a000/1e78a380.i2c-bus/i2c-6/6-002f/hwmon/**/pwm1
gb_fan_2=/sys/devices/platform/ahb/ahb:apb/ahb:apb:bus@1e78a000/1e78a380.i2c-bus/i2c-6/6-002f/hwmon/**/pwm2
gb_fan_3=/sys/devices/platform/ahb/ahb:apb/ahb:apb:bus@1e78a000/1e78a380.i2c-bus/i2c-6/6-002f/hwmon/**/pwm3
gb_fan_4=/sys/devices/platform/ahb/ahb:apb/ahb:apb:bus@1e78a000/1e78a380.i2c-bus/i2c-6/6-002f/hwmon/**/pwm4

#I2C PWM Value (0-255) , for 80% setting pwm value to 204
if [ -f $mb_fan_1 ];then
	echo 204 > $mb_fan_1; echo "FAN_1 value set to 80%"
else
	echo " FAN_1 not connected or running "
        phosphor_log "FAN_1 not connected or running" $sevErr
fi

if [ -f $mb_fan_2 ];then
	echo 204 > $mb_fan_2; echo "FAN_2 value set to 80%"
else
	echo " FAN_2 not connected or running "
        phosphor_log "FAN_2 not connected or running" $sevErr
fi

if [ -f $mb_fan_3 ];then
	echo 204 > $mb_fan_3; echo "FAN_3 value set to 80%"
else
	echo " FAN_3 not connected or running "
        phosphor_log "FAN_3 not connected or running" $sevErr
fi

if [ -f $mb_fan_4 ];then
	echo 204 > $mb_fan_4; echo "FAN_4 value set to 80%"
else
	echo " FAN_4 not connected or running "
        phosphor_log "FAN_4 not connected or running" $sevErr
fi

if [ -f $gb_fan_1 ];then
	echo 204 > $gb_fan_1; echo "FAN_5 value set to 80%"
else
	echo " FAN_5 not connected or running "
        phosphor_log "FAN_5 not connected or running" $sevErr
fi

if [ -f $gb_fan_2 ];then
	echo 204 > $gb_fan_2; echo "FAN_6 value set to 80%"
else
	echo " FAN_6 not connected or running "
        phosphor_log "FAN_6 not connected or running" $sevErr
fi

if [ -f $gb_fan_3 ];then
	echo 204 > $gb_fan_3; echo "FAN_7 value set to 80%"
else
	echo " FAN_7 not connected or running "
        phosphor_log "FAN_7 not connected or running" $sevErr
fi

if [ -f $gb_fan_4 ];then
	echo 204 > $gb_fan_4; echo "FAN_8 value set to 80%"
else
	echo " FAN_8 not connected or running "
        phosphor_log "FAN_8 not connected or running" $sevErr
fi
