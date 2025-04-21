#!/bin/sh

source /usr/bin/system_state_files.sh

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

#
# Exchange STANDBY_POWER_PG via a tmp file with stbypowerctrl.sh
# standby_power_status_monitor.sh captures the real GPIO line and mirrors it's
# status to the file.
#
if [ ! -d "$STATE_FILE_PATH" ]; then
    mkdir $STATE_FILE_PATH
fi

get_gpio() #(pin)
{
    local pin=$1;shift
    gpioget `gpiofind "$pin"`
}

stbypwrsts_pin="STBY_POWER_PG-I"
pin_val=`get_gpio "$stbypwrsts_pin"`
echo "Standby Power Status Monitor starts with STBY_POWER_PG-I = $pin_val"
echo $pin_val > $STANDBY_POWER_PG_FILE

# Notify systemd that service has started
systemd-notify --ready --status="Entering STBY_POWER_PG-I monitor Loop"

# Main
while true; do

    gpiomon --num-event=1 `gpiofind "$stbypwrsts_pin"`
    
    pin_val=`get_gpio "$stbypwrsts_pin"`
    echo $pin_val > $STANDBY_POWER_PG_FILE
    echo "$stbypwrsts_pin changes to $pin_val"

    if [ "$pin_val" == "1" ]; then
        phosphor_log "Baseboard Standby Power ON." $sevNot
    else
        phosphor_log "Baseboard Standby Power OFF." $sevNot
    fi

done
