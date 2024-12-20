#!/bin/bash

BMC_IP=172.31.13.241
HMC_IP=172.31.13.251

declare -i loop_delay=5

function wait_for_hmc_ready()
{
    local gpioname="HMC_READY-I"
    local delay_secs=1
    hmc_status=-1
    trycnt=1
    until [[ $hmc_status -eq 0 ]]
    do
        # Check if /xyz/openbmc_project/software/FW_RECOVERY_HGX_FW_BMC_0 exist
        # If yes, then HMC is in recovery mode
        hmc_status=$(busctl tree com.Nvidia.FWStatus | grep -c "FW_RECOVERY_HGX_FW_BMC_0")
        if [ $hmc_status -eq 1 ]; then
            sleep $delay_secs
        fi

        # log an error every 60 seconds
        if [ $((trycnt % 60)) -eq 0 ]; then
            echo "[ERROR] HMC_READY_I = 0, HMC has not booted"
        fi
        ((trycnt++))
    done
}

function wait_for_hmc_ping()
{
    local delay_secs=5
    trycnt=1
    max_retries=120
    while true; do
        # Ping HMC
        ping -c 5 $HMC_IP > /dev/null
        rc=$?
        if [[ $rc -eq 0 ]]; then
            echo "[INFO] HMC is responding to ping"
            return 0
        fi

        # If HMC does not respond, log an error and exit with return code
        if [ $trycnt -ge $max_retries ]; then
            echo "[ERROR] HMC not responding to ping"
            return 1
        fi
        ((trycnt++))
        sleep $delay_secs
    done
}

function check_hmcusb0_status()
{
    usb_status=$(networkctl status hmcusb0 | grep 'Online state:' | sed 's/^[^:]*[:]//')
    if [[ $usb_status != *"online"* ]]; then
        return 1
    fi

    return 0
}

function rebind_usb_driver()
{
    echo 1e6a3000.usb > /sys/bus/platform/drivers/ehci-platform/unbind
    echo 1e6a3000.usb > /sys/bus/platform/drivers/ehci-platform/bind
    # Wait 5 seconds for USB driver init
    sleep 5

    ip_string=$(networkctl status hmcusb0 | grep -v 'Hardware' | grep ' Address: ' | sed 's/^[^:]*[:]//')
    if [[ "$ip_string" != *"$BMC_IP"* ]]; then
        echo "Bad IP Configuration on hmcusb0"
        echo "Adding default static ip"
        ifconfig hmcusb0 $BMC_IP up
    fi
}

############################### main ##########################################
while true; do

    check_hmcusb0_status
    rc=$?
    if [[ $rc -ne 0 ]]; then
        # USB connection is down, attempt to recover
        rebind_usb_driver
        wait_for_hmc_ping
        ping_rc=$?
        if [[ $ping_rc -eq 0 ]]; then
            echo "[INFO] BMC/HMC USB Connection restored"
        else
            echo "[ERROR] Failed to restore BMC/HMC USB Connection"
        fi
    fi
    sleep $loop_delay
done