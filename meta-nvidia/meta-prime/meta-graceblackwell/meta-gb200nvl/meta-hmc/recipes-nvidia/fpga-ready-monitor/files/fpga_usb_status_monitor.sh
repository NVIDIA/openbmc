#!/bin/bash

FPGA_USB_DEVICE="0955:ffff"

#USB link heartbeat interval
declare -i loop_delay=20

function query_usb_device()
{
    lsusb -tv | grep "$FPGA_USB_DEVICE"
}

function check_fpga_usb_status()
{
    prev_state=$1
    dev=$(query_usb_device)
    if [[ -z "$dev" ]]; then
        echo "ERROR: HMC-FPGA USB link is down"
        return 1
    fi
    # Log if USB link came back up
    # Only print if previous state was down
    # to prevent spamming logs
    if [[ "$prev_state" -eq 1 ]]; then
        echo "INFO: HMC-FPGA USB link is up"
    fi
    return 0
}

function rebind_usb_driver()
{
    echo "1e6a1000.usb" > /sys/bus/platform/drivers/ehci-platform/unbind
    sleep 0.5
    echo "1e6a1000.usb" > /sys/bus/platform/drivers/ehci-platform/bind
    # Wait 5 seconds for USB driver init
    sleep 5
}

############################### main ##########################################
down=0
while true; do

    check_fpga_usb_status "$down"
    rc=$?
    if [[ $rc -ne 0 ]]; then
        # USB connection is down, attempt to recover
        rebind_usb_driver
        check_fpga_usb_status "0"
        rc=$?
        if [[ $rc -eq 0 ]]; then
            echo "[INFO] HMC-FPGA USB Connection restored"
            # Start mctp-usb-ctrl service to re-enable MCTP over USB
            systemctl stop mctp-usb-ctrl.service
            systemctl restart mctp-usb-demux.service
            sleep 2
            systemctl start mctp-usb-ctrl.service
            down=0
        else
            echo "[ERROR] Failed to restore HMC-FPGA USB Connection"
            down=1
        fi
    else
        down=0
    fi
    sleep ${loop_delay}
done