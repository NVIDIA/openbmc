#!/bin/sh

source /usr/bin/system_state_files.sh

get_gpio() #(pin)
{
    local pin=$1;shift
    gpioget `gpiofind "$pin"`
}

#
# Gets RUN_POWER_PG
# If monitor is active, get it from the file
# Else get it from the GPIO
#
get_run_power_pg()
{
    power_monitor_active=`systemctl is-active nvidia-power-monitor`

    if [ $power_monitor_active != "active" ]; then
    {
        # If power-status-monitor not active, just get it from the GPIO
        echo `get_gpio RUN_POWER_PG-I`
    }
    else
    {
        if [ -f "$RUN_POWER_PG_FILE" ]; then
        {
            echo `cat $RUN_POWER_PG_FILE`
        }
        else
        {
            #
            # If RUN_POWER_PG_FILE does not exist, the power monitor may not be started
            # so assuming power off
            #
            echo "0"
        }
        fi
    }
    fi
}
