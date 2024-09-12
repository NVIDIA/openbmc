#!/bin/bash

BMC_IP=172.31.13.241
HMC_IP=172.31.13.251

declare -i loop_delay=5
hmcusb0_disconnected=false

function wait_for_hmc_ready()
{
    local gpioname="HMC_READY-I"
    local delay_secs=1
    hmc_status=0
    trycnt=1
    until [[ $hmc_status -gt 0 ]]
    do
        # TODO: The logic for checking hmc status might change in the future
        hmc_status=$(busctl get-property com.Nvidia.FWStatus \
        /xyz/openbmc_project/software/FW_RECOVERY_HGX_FW_BMC_0 \
        xyz.openbmc_project.State.Decorator.Health Health | grep -c "xyz.openbmc_project.State.Decorator.Health.HealthType.OK")
        if [ $hmc_status -eq 0 ]; then
            sleep $delay_secs
        fi

        # log an error every 60 seconds
        if [ $((trycnt % 60)) -eq 0 ]; then
            echo "[ERROR] HMC_READY_I = 0, HMC has not booted"
        fi
        ((trycnt++))
    done
}

function update_hmcusb0_status()
{
    usb_status=$(networkctl status hmcusb0 | grep 'Online state:' | sed 's/^[^:]*[:]//')
    if [[ $usb_status != *"online"* ]]; then
        hmcusb0_disconnected=true
    fi

    ping -c 3 $HMC_IP > /dev/null
    if [[ $? != 0 ]]; then
        hmcusb0_disconnected=true
    fi
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
    # init to false for each cycle
    hmcusb0_disconnected=false
    # Wait for HMC to signal ready
    wait_for_hmc_ready
    update_hmcusb0_status
    if [ "$hmcusb0_disconnected" == "true" ]; then
        rebind_usb_driver
    fi
    sleep $loop_delay
done