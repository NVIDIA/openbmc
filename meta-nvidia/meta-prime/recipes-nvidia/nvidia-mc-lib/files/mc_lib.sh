#!/bin/bash

# Management Controller function libraries
# NOTE: All of these scripts are sourced when this file is sourced, see MAIN below
mc_function_files=(
"/etc/default/nvidia_event_logging.sh"  # Phophor event logging xyz.openbmc_project.Logging.service
"/usr/bin/gpio_check.sh"                # GPIO level test
"/usr/bin/gpio_tools.sh"                # GPIO libraries
"/usr/bin/filesystem_check.sh"          # Confirm MC filesystems
)

source /usr/bin/system_state_files.sh

get_gpio() #(pin)
{
    local pin=$1;shift
    gpioget `gpiofind "$pin"`
}

#
# Exchange RUN_POWER_PG via a tmp file with nvidia-power-monitor
# power_status_monitor.sh captures the real GPIO line and mirrors it's
# status to the file.
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

#
# Exchange STANDBY_POWER_PG via a tmp file with nvidia-power-monitor
# standby_power_status_monitor.sh captures the real GPIO line and mirrors it's
# status to the file.
#
get_stby_power_pg()
{
    if [ -f "$STANDBY_POWER_PG_FILE" ]; then
        STBY_POWER_PG=`cat $STANDBY_POWER_PG_FILE`
    else
        #
        # If STBY_POWER_PG is empty
        # so assuming power off is a safe bet
        #
        STBY_POWER_PG=0
    fi
    echo "$STBY_POWER_PG"
}

run_gpumgr_or_mctp()
{
    # If power is off, we should start gpumgr and mctp
    gpival=`get_run_power_pg`
    if [ "$gpival" == "0" ] ; then
        echo 1
        return
    fi

    # If the boot timed out (CPU_BOOT_TIMEOUT_FILE file exists),
    # we should start gpumgr and mctp
    if [ -f "$CPU_BOOT_TIMEOUT_FILE" ] ; then
        echo 1
        return
    fi

    if [ "$gpival" == "1" ] ; then
        # If power is up and we take a random PERST, we should start gpumgr
        # and mctp
        if [ -f $CPU_BOOT_COMPLETE_FILE ]; then
            echo 1
            return
        fi
    fi

    echo 0
}

run_gpumgr()
{
    # If this is the first run (GPU_MANAGER_INITIALIZED file does not exist),
    # we should start gpumgr
    if [ ! -f "$GPU_MANAGER_FIRST_TIME_INIT_FILE" ] ; then
        echo 1
        return
    fi

    RUN_GPU_MGR=`run_gpumgr_or_mctp`
    echo $RUN_GPU_MGR
}

run_mctp()
{
    # If this is the first run (MCTP_INITIALIZED file does not exist),
    # we should start gpumgr and mctp
    if [ ! -f "$MCTP_FIRST_TIME_INIT_FILE" ] ; then
        echo 1
        return
    fi

    RUN_MCTP=`run_gpumgr_or_mctp`
    echo $RUN_MCTP
}

#######################################
# Source all library scripts in the mc_function_files array
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Success, all scripts
#   1 Error, at least one script failed to be sourced
source_mc_functions()
{
    status=0
    # Iterate through the list of files and source each one
    for mc_function_file in "${mc_function_files[@]}"
    do
        if [[ -f $mc_function_file ]]; then
            source $mc_function_file
            rc=$?
            if [[ $rc -ne 0 ]]; then
                echo "$mc_function_file exists but failed to source"
                status=1
            else
                echo "$mc_function_file was sourced successfully"
            fi
        else
            echo "$mc_function_file does not exist, can not be sourced"
            status=1
        fi
    done
    return $status
}

#### MAIN ####
# Source bmc common scripts when this file is sourced
source_mc_functions
