#!/bin/bash

source /usr/bin/mc_lib.sh
source /usr/bin/system_state_files.sh

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

# Get platform variables
source /etc/default/platform_var.conf

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

# Get power status at GPIO level (requires stopping service the owns the GPI)
gpio_power_status()
{
    # Stop/Start nvidia-power-monitor because it owns RUN_POWER_PG-I
    systemctl stop nvidia-power-monitor

    echo -n "Host Run Power Status : "
    local val=`get_gpio RUN_POWER_PG-I`
    if [ "$val" == "0" ]; then
        echo "OFF"
    else
        echo "Good / ON"
    fi

    systemctl start nvidia-power-monitor
}

#
# Asserted LOW  SHDN_OK_L-I
#
get_shutdown_ok_l()
{
    SHDN_OK=`cat $SHDN_OK_FILE`
    echo $SHDN_OK
}

power_on()
{
    echo "Power On Host"

    local gpival=`get_run_power_pg`
    if [ "$gpival" == "1" ]; then
        echo "Host is already powered on"
	return 0
    fi

    if [[ -f "$CPU_BOOT_COMPLETE_FILE" ]]; then
        rm $CPU_BOOT_COMPLETE_FILE
    fi

    if [[ -f "$CPU_BOOT_TIMEOUT_FILE" ]]; then
        rm $CPU_BOOT_TIMEOUT_FILE
    fi

    #
    # Deassert some GPIOs that should already not be asserted right now
    #
    echo "Deasserting SHDN_REQ_L-O = 1"
    set_gpio SHDN_REQ_L-O 1
    echo "Deasserting SHDN_FORCE_L-O = 1"
    set_gpio SHDN_FORCE_L-O 1  

    #
    # Assert SYS_RST_IN_L-O in prep for power on
    #
    echo "Asserting SYS_RST_IN_L-O to hold host in reset"
    set_gpio SYS_RST_IN_L-O 0

    #
    # Write RUN_POWER_EN-O=1 to turn on the run power to the FPGA
    #
    # set_gpio RUN_POWER_EN-O 1
    echo "Asserting RUN_POWER_EN-O = 1"
    echo 1 > /sys/class/gpio/gpio${sysfs_run_power}/value

    #
    # Wait for RUN_POWER_PG from FPGA
    #
    echo 'Waiting for RUN_POWER_PG-I to go high'
    gpival=0
    trycnt=1
    until [[ $gpival -gt 0 || $trycnt -gt 200 ]]
    do
        gpival=`get_run_power_pg`
        echo "RUN_POWER_PG-I = $gpival"
        if [ $gpival -eq 0 ]; then
            sleep 0.1
        fi
        ((trycnt++))
    done
    if [ $gpival -eq 0 ]; then
        echo "RUN_POWER_EN-O: RUN_POWER_PG-I failed to assert after 20 seconds. Power On Failed."
        phosphor_log "RUN_POWER_EN-O: RUN_POWER_PG-I failed to assert after 20 seconds. Power On Failed" $sevErr
        
        echo "Doing Force Shutdown"
        do_shutdown_force

        exit 1
    fi

    # NVME CPLDs can only be powered up when RUN_POWER_PG-I=1, so NVMe CPLD
    # bindings must be done here to ensure that nvme FRUs/sensors/devices behind
    # CPLD MUX devices can be probed before a power-state change is detected
    # by FruDevice and EntityManager.
    /usr/bin/nvme_cpld_probe.sh

    #
    # Write SYS_RST_IN_L-O to release system reset
    #
    echo "Deasserting SYS_RST_IN_L-O = 1 to release host to boot"
    set_gpio SYS_RST_IN_L-O 1

    #
    # Wait for system released from reset
    #
    echo 'Waiting for SYS_RST_OUT_L-I to go high'
    gpival=0
    trycnt=1
    until [[ $gpival -gt 0 || $trycnt -gt 200 ]]
    do
        gpival=`get_gpio SYS_RST_OUT_L-I`
        echo "SYS_RST_OUT_L-I = $gpival"
        if [ $gpival -eq 1 ]; then
            sleep 0.1
        fi
        ((trycnt++))
    done
    if [ $gpival -eq 0 ]; then
        phosphor_log "SYS_RST_IN_L-O: SYS_RST_OUT_L-I failed to assert after 20 seconds." $sevErr
        exit 1
    fi

    echo "Released System Reset Successfully"

    sleep 5

    gpival=`get_run_power_pg`
    if [ "$gpival" == "1" ]; then
        # main log entry comes from nvidia-power-monitor
        echo "Powered On Host Successfully"
        return 0
    else
        phosphor_log "Host Failed to Power ON." $sevErr
        echo "Host Power On Failed"

        exit 1
    fi
}

do_shutdown_force()
{

    #
    # Deassert some GPIOs that should already not be asserted right now
    #
    echo "Deasserting SHDN_REQ_L-O = 1"
    set_gpio SHDN_REQ_L-O 1
    echo "Deasserting SHDN_FORCE_L-O = 1"
    set_gpio SHDN_FORCE_L-O 1  

    #
    # Assert SHDN_FORCE_L-O to force shutdown
    #
    echo "Asserting SHDN_REQ_L-O = 0"
    set_gpio SHDN_REQ_L-O 0
    echo "Asserting SHDN_FORCE_L-O = 0"
    set_gpio SHDN_FORCE_L-O 0

    #
    # Wait for SHDN_OK_L-I=0 from FPGA
    #
    echo 'Waiting for SHDN_OK_L-I to assert (low)'
    local gpival=1
    trycnt=1
    until [[ $gpival -eq 0 || $trycnt -gt 80 ]]
    do
        gpival=`get_shutdown_ok_l`
        echo "SHDN_OK_L-I = $gpival"
        if [ $gpival -eq 1 ]; then
            sleep 0.5
        fi
        ((trycnt++))
    done
    if [ $gpival -eq 1 ]; then
        echo "SHDN_FORCE_L-O: SHDN_OK_L-I failed to assert after 40 seconds.  Power Off Host Failed."
        phosphor_log "SHDN_FORCE_L-O: SHDN_OK_L-I failed to assert after 40 seconds.  Power Off Host Failed." $sevErr

        #
        # Deassert SHDN_FORCE_L-O and SHDN_REQ_L-O
        #
        echo "Deasserting SHDN_FORCE_L-O = 1"
        set_gpio SHDN_FORCE_L-O 1
        echo "Deasserting SHDN_REQ_L-O = 1"
        set_gpio SHDN_REQ_L-O 1

        return 1
    fi

    #
    # RUN_POWER_EN-O=0
    #
    echo "Set RUN_POWER_EN-O = 0"
    echo 0 > /sys/class/gpio/gpio${sysfs_run_power}/value
    
    #
    # Wait for RUN_POWER_PG=0 from FPGA
    #
    echo 'Waiting for RUN_POWER_PG-I to go low'
    local gpival=1
    trycnt=1
    until [[ $gpival -eq 0 || $trycnt -gt 80 ]]
    do
        gpival=`get_run_power_pg`
        echo "RUN_POWER_PG-I = $gpival"
        if [ $gpival -eq 1 ]; then
            sleep 0.5
        fi
        ((trycnt++))
    done

    if [ $gpival -eq 0 ]; then
        echo "Power Off Host Succeeded"
    else
        echo "Power Off Host Failed after 40 seconds."
        phosphor_log "SHDN_FORCE_L-O: RUN_POWER_PG-I failed to deassert after 40 seconds.  Power Off Host Failed." $sevErr

        #
        # Deassert SHDN_FORCE_L-O and SHDN_REQ_L-O
        #
        echo "Deasserting SHDN_FORCE_L-O = 1"
        set_gpio SHDN_FORCE_L-O 1
        echo "Deasserting SHDN_REQ_L-O = 1"
        set_gpio SHDN_REQ_L-O 1

        return 1
    fi
    
    #
    # Deassert SHDN_FORCE_L-O and SHDN_REQ_L-O
    #
    echo "Deasserting SHDN_FORCE_L-O = 1"
    set_gpio SHDN_FORCE_L-O 1
    echo "Deasserting SHDN_REQ_L-O = 1"
    set_gpio SHDN_REQ_L-O 1

    return 0
}

do_shutdown_request()
{
    #
    # Deassert some GPIOs that should already not be asserted right now
    #
    echo "Deasserting SHDN_REQ_L-O = 1"
    set_gpio SHDN_REQ_L-O 1
    echo "Deasserting SHDN_FORCE_L-O = 1"
    set_gpio SHDN_FORCE_L-O 1  

    #
    # Write SHDN_REQ_L-O=0 to request for shutdown
    #
    echo "asserting SHDN_REQ_L-O"
    set_gpio SHDN_REQ_L-O 0

    #
    # 1 second of request assertion
    #
    sleep 0.5

    #
    # Write SHDN_REQ_L-O=1 to release (latched)
    #
    echo "deasserting SHDN_REQ_L-O"
    set_gpio SHDN_REQ_L-O 1

    #
    # Wait for RUN_POWER_PG=0 from FPGA
    #
    echo 'Waiting for RUN_POWER_PG-I to go low'
    local gpival=1
    trycnt=1
    until [[ $gpival -eq 0 || $trycnt -gt 240 ]]
    do
        gpival=`get_run_power_pg`
        echo "RUN_POWER_PG-I = $gpival"
        if [ $gpival -eq 1 ]; then
            sleep 0.5
        fi
        ((trycnt++))
    done
    if [ $gpival -eq 0 ]; then
        echo "Graceful Shutdown Host Succeeded"
    else
        echo "Graceful Shutdown Host Failed after 2 minutes."
        phosphor_log "SHDN_REQ_L-O: RUN_POWER_PG-I failed to deassert after 2 minutes.  Graceful Shutdown Host Failed." $sevErr

        echo "Revert PowerState to actual chassis power state."
        # The power is good and passes Powering On stage, the actual chassis power status is "On"
        # Use the RequestedHostTransition to address the power-on state to let the power sequence work normally
        busctl set-property xyz.openbmc_project.State.Host /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.Host \
            RequestedHostTransition s xyz.openbmc_project.State.Host.Transition.On
    fi

    #
    # We don't have to wait for SHDN_OK_L-I
    # Wait for nvidia-shutdown-ok monitor to turn of RUN_POWER_EN-O
    # nvidia-power-monitor will shut down local run power
    # and do other cleanup
    #
}

#
# Response to short button press - Graceful OS shutdown
#
grace_off()
{
    echo "Request Graceful Power Off Host"

    local gpival=`get_run_power_pg`
    if [ "$gpival" == "0" ]; then
        echo "Host is already powered off"
        return 0
    fi

    do_shutdown_request

    # This will do everything to remove RUN Power asynchronously.
    # This may fail or take a while because it involves an OS shutdown.
    # Let Redfish Host Interface User Del and Logging happen in Power Monitor
}

#
# Response to 4sec ACPI button press - Ungraceful immediate power off
#
power_off()
{
    echo "Force Power Off Host"

    local gpival=`get_run_power_pg`
    if [ "$gpival" == "0" ]; then
        echo "Host is already powered off"
        return 0
    fi

    do_shutdown_force

    # Let Redfish Host Interface User Delete and Logging happen in nvidia-power-monitor
}

power_cycle()
{
    power_off
    sleep 5
    power_on
    # Let Redfish Host Interface User Delete and Logging happen in nvidia-power-monitor
    return 0
}

reset()
{
    #
    # Assert SYS_RST_IN_L-O to pulse system reset
    #
    echo "Asserting SYS_RST_IN_L-O = 0 to pulse system reset"
    set_gpio SYS_RST_IN_L-O 0

    #
    # Wait 5s before setting SYS_RST_IN_L-O = 1
    # Need to give the system time to stablize
    #
    sleep 5

    #
    # Deassert SYS_RST_IN_L-O to release system reset
    #
    echo "Deasserting SYS_RST_IN_L-O = 1 to release system reset"
    set_gpio SYS_RST_IN_L-O 1

    echo 'Started System Reset'
}

power_status()
{
    echo -n "Host Run Power Status : "
    local val=`get_run_power_pg`
    if [ "$val" == "0" ]; then
        echo "OFF"
    else
        echo "Good / ON"
    fi

    return 0
}

enable_power_brake()
{
    echo "Asserting power brake"
    set_gpio PWR_BRAKE_L-O 0
}

disable_power_brake()
{
    echo "Deasserting power brake"
    set_gpio PWR_BRAKE_L-O 1
}

### MAIN ###
if [ $# -eq 0 ]; then
    echo "$0 <power_status|power_on|power_off|grace_off|power_cycle|enable_power_brake|disable_power_brake>"
    echo "    power_off:  immediate force power off"
    echo "    grace_off:  orderly shutdown request to host - may not be honored by OS."
    exit 1
fi

echo "Host Power Control"

#
# Don't let this ever run before bmc_ready.sh has completed successfully
#
bmc_ready=`systemctl is-active bmc-boot-complete`
if [ $bmc_ready != "active" ]; then
    echo "powerctrl.sh cannot run because bmc-boot-complete (bmc_ready.sh) has not activated successfully"
    phosphor_log "powerctrl.sh cannot run because bmc-boot-complete (bmc_ready.sh) has not activated successfully" $sevErr
    exit 1
fi

$*
