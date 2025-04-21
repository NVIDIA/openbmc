#!/bin/sh

source /usr/bin/system_state_files.sh

# Get platform variables
source /etc/default/platform_var.conf

#
# Exchange SHDN_OK_L via a tmp file with powerctrl.sh
# power_status_monitor.sh captures the real GPIO line and mirrors it's
# status to the file.
#

get_gpio() #(pin)
{
    local pin=$1;shift
    gpioget `gpiofind "$pin"`
}

set_gpio() # (pin, value)
{
    local pin=$1;shift
    local value=$1;shift
    echo gpioset $pin = $value
    gpioset -m exit `gpiofind "$pin"`=$value
}

pwrsts_pin="SHDN_OK_L-I"
pin_val=`get_gpio "$pwrsts_pin"`
echo "Shutdown OK Monitor starts with SHDN_OK_L-I = $pin_val"
echo $pin_val > $SHDN_OK_FILE

# Main
while true; do

    gpiomon --num-event=1 `gpiofind "$pwrsts_pin"`
    
    pin_val=`get_gpio "$pwrsts_pin"`
    echo $pin_val > $SHDN_OK_FILE
    echo "SHDN_OK_L-I = $pin_val"

    if [ "$pin_val" == "0" ]; then
        #
        # Assert SYS_RST_IN_L-O = 0
        #
        echo "Asserting SYS_RST_IN_L-O to hold host in reset"
        set_gpio SYS_RST_IN_L-O 0

        #
        # Write RUN_POWER_EN-O=0
        #
        # 2 second sleep need due to a HW issue - remove later
        sleep 2
        echo "Set RUN_POWER_EN-O = 0"
        #set_gpio RUN_POWER_EN-O 0
        echo 0 > /sys/class/gpio/gpio${sysfs_run_power}/value  
    fi

done
