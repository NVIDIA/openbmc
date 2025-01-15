#!/bin/bash

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

# Inherit bmc functions library
source /usr/bin/mc_lib.sh

# Get platform variables
source /etc/default/platform_var.conf

source /usr/bin/mc_lib.sh # For get_stby_power_pg function

#
# Exchange STANDBY_POWER_PG via a tmp file with nvidia-power-monitor
# standby_power_status_monitor.sh captures the real GPIO line and mirrors it's
# status to the file.
#
get_gpio() #(pin)
{
    local pin=$1;shift
    gpioget `gpiofind "$pin"`
}

power_on()
{
    #
    # Standby Power On to the baseboard
    #
    echo "Turning standby power on (may take around 30 seconds)"
    systemctl start nvidia-standby-poweron
}

bmc_set_initial_gpio_out()
{
    # Initialize GPIO out state
    # After STBY power is on to aovid creating leaky path
    # Every signal should be set to 0

    # RUN_POWER_EN-O
    echo 0 > /sys/class/gpio/gpio${sysfs_run_power}/value 
    echo 'Set RUN_POWER_EN-O=0'

    gpioset -m exit `gpiofind "EROT_FPGA_RST_L-O"`=0
    echo 'Set EROT_FPGA_RST_L-O=0'

    gpioset -m exit `gpiofind "FPGA_RST_L-O"`=0
    echo 'Set FPGA_RST_L-O=0'

    gpioset -m exit `gpiofind "PWR_BRAKE_L-O"`=0
    echo 'Set PWR_BRAKE_L-O=0'

    gpioset -m exit `gpiofind "SHDN_REQ_L-O"`=0
    echo 'Set SHDN_REQ_L-O=0'

    gpioset -m exit `gpiofind "SHDN_FORCE_L-O"`=0
    echo 'Set SHDN_FORCE_L-O=0'

    gpioset -m exit `gpiofind "SYS_RST_IN_L-O"`=0
    echo 'Set SYS_RST_IN_L-O=0'

    gpioset -m exit `gpiofind "GLOBAL_WP_BMC-O"`=0
    echo 'Set GLOBAL_WP_BMC-O=0'
}

power_off_internal()
{
    # Ensure Run Power is Off first
    local val=`get_run_power_pg`
    if [ "$val" == "1" ]; then
        echo "Run Power is ON - must turn off before standby power off"
        exit 1
    fi

    # See if Standby Power is already off
    local val=`get_stby_power_pg`
    if [ "$val" == "0" ]; then
        echo "Standby is already powered off"
        exit 0
    fi

    # Stopping init-time services
    #echo "Stopping bmc-boot-complete.service"
    #systemctl stop bmc-boot-complete.service
    # do this via the systemd dependencies in the service file but also here to help with debug manual running of script

    # Setting other GPOs back to initial conditions
    bmc_set_initial_gpio_out
    #
    # Write STBY_POWER_EN=1 to turn on the standby power to the FPGA and let it boot
    #
    gpioset -m exit `gpiofind "STBY_POWER_EN-O"`=0
    echo 'Disabled STBY_POWER_EN-O=0'

    #
    # Unexport GPOs (outputs only) that need to be shared across processes
    #
    # RUN_POWER_EN-O
    echo ${sysfs_run_power} > /sys/class/gpio/unexport

    echo "Standby Power Off Successful"
    exit 0
}

power_status()
{
    echo -n "Standby Power Status : "
    local val=`get_stby_power_pg`
    if [ "$val" == "0" ]; then
        echo "OFF"
    else
        echo "Good / ON"
    fi

    exit 0
}

#
# Check to see if its OK to turn off standby power
# This is called only by the standby power off service and logs an event if it can't
#
ok_to_power_off()
{
    run_power=`get_run_power_pg`

    echo "RUN_POWER_PG = $run_power"

    if [ $run_power != "0" ]; then
    {
            echo 'Cannot disable standby power because run power is still enabled.'
            phosphor_log "Cannot disable standby power because run power is still enabled." $sevErr
            exit 1
    }
    else
    {
            exit 0
    }
    fi
}

#
# Directly callable version
# the real work is in power_off_internal called by the systemd service
#
power_off()
{
    # Ensure Run Power is Off
    local val=`get_run_power_pg`
    if [ "$val" == "1" ]; then
        echo "Run Power is ON - must turn off before standby power off"
        exit 1
    fi

    #
    # Standby Power Off to the baseboard
    #
    echo "Turning standby power off (may take around 15 seconds)"
    systemctl start nvidia-standby-poweroff
    sleep 3

    # Ensure Run Power is Off
    local val=`get_stby_power_pg`
    if [ "$val" == "1" ]; then
        echo "Standby Power is still ON - power off failed"
        exit 1
    fi

    echo "Standby Power is OFF"
}

#
# Callable directly from user at SSH
# Orderly stop of run power, standby power, and BMC aux cycle
# Do NOT run this from a systemd service.
#
aux_cycle()
{
    #
    # Run Power Off
    #
    echo "Turning Run Power Off using obmcutil poweroff"
    obmcutil poweroff

    echo "Waiting 30 seconds for services to cleanly shut down"
    sleep 30

    # Ensure Run Power is Off
    local val=`get_run_power_pg`
    if [ "$val" == "1" ]; then
        echo "Graceful power off failed. Will use hard power off"
        obmcutil chassisoff
        echo "Waiting 30 seconds for services to cleanly shut down"
        sleep 30
        val=`get_run_power_pg`
        if [ "$val" == "1" ]; then
        {
            if [ "$1" == "force" ]; then
            {
                echo "Run Power is ON but force is provided. Shutting down regardless"
            }
            else
            {
                echo "Run Power is ON - must turn off before standby power off"
                exit 1
            }
            fi
        }
        fi
    fi

    #
    # The GPIO Expander for BMC_STBY_CYCLE-O below is on standby power
    # so do not remove standby power first.
    #

    #
    # BMC Module self power cycle
    #
    echo "BMC module self power cycle...See you in 2 minutes"
    sleep 3
    gpioset -m exit `gpiofind "BMC_STBY_CYCLE-O"`=1
}

### MAIN ###
if [ $# -eq 0 ]; then
    echo "$0 <power_status|power_on|power_off|aux_cycle>"
    exit 1
fi

echo "Standby Power Control"

$*
