#!/bin/bash

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

fan_prefix=/sys/bus/i2c/devices/

all_fans=(
${fan_prefix}6-0020/hwmon/**/pwm1
${fan_prefix}6-0020/hwmon/**/pwm2
${fan_prefix}6-0020/hwmon/**/pwm3
${fan_prefix}6-0020/hwmon/**/pwm4

${fan_prefix}6-0023/hwmon/**/pwm1
${fan_prefix}6-0023/hwmon/**/pwm2
${fan_prefix}6-0023/hwmon/**/pwm3
${fan_prefix}6-0023/hwmon/**/pwm4
)

systemctl stop phosphor-pid-control

pwm_val=$(( 255*$1 / 100 ))

# Set all fan's PWM to user selected speed
for i in ${!all_fans[@]}; do
        fan_num=$(($i + 1))
        fan_path=${all_fans[$i]}
        if [ -f $fan_path ];then
                echo $pwm_val > $fan_path; echo "FAN_HEADER_$fan_num value set to ${1}%"
        else
                echo " FAN_HEADER_$fan_num not connected or running "
                phosphor_log "FAN_HEADER_$fan_num not connected or running" $sevErr
        fi
done
