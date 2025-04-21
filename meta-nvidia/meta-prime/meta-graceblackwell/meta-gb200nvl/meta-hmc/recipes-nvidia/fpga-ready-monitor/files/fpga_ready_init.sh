#!/bin/sh
source /etc/default/nvidia_event_logging.sh
#
# A number of GPU related services rely upon this on/off signal
#

# Fixed https://nvbugspro.nvidia.com/bug/4773976
# Background: The window between subsequent gpiomon calls in the main loop
# Cannot be large as we could miss an FPGA_READY transition. We overcome this 
# by reducing the window by comparing the new FPGA_READY value to the 
# previous iteration and including a timeout to prevent us from sleeping 
# on a stale value forever.
FPGA0_RDY_PIN="FPGA0_READY-I"
FPGA_USB_DEVICE="0955:ffff"
polling_timeout=10

get_FPGA_READY() #(pin)
{
    gpioget `gpiofind "$FPGA0_RDY_PIN"`
}

query_usb_device()
{
	lsusb -tv | grep "$FPGA_USB_DEVICE"
}

get_usb_link_status()
{
    count=0
    while [[ $count -le $polling_timeout ]]; do
        dev=$(query_usb_device)
        if [[ -z "$dev" ]]; then
            sleep 1
            count=$((count+1))
        else
			echo "HMC-FPGA USB link is ready"
            return 1
        fi
    done
    echo "ERROR: Timed out waiting $polling_timeout seconds, resetting HMC-FPGA USB link"
	#Issue an EHCI USB driver reset
	echo "1e6a1000.usb" > /sys/bus/platform/drivers/ehci-platform/unbind
	sleep 0.5
	echo "1e6a1000.usb" > /sys/bus/platform/drivers/ehci-platform/bind
	sleep 1
	dev=$(query_usb_device)
	if [[ -z "$dev" ]]; then
		echo "ERROR: Failed to reset HMC-FPGA USB link"
		phosphor_log "fpga_ready_init: ERROR HMC-FPGA USB link is down" $sevErr
		return 0
	fi
	echo "HMC-FPGA USB link is ready"
    return 1
}

echo "Checking initial status of $FPGA0_RDY_PIN"
# Wait for the FPGA to boot up, without using gpiomon
# to avoid race.
# Time out: ~120s
t="0"
while [ $t -le "240" ]; do
	pin_val=`get_FPGA_READY`
	if [ "$pin_val" == "1" ]; then
		# Ready
		# WAR: Currently, when FPGA0_RDY_PIN is asserted, the FPGA isn't actually
		# ready. Add a 10 second sleep here as a software WAR until we can fix
		# the FPGA to resolve the issue.
		sleep 10
		get_usb_link_status
		echo "$FPGA0_RDY_PIN is set, starting set-fpga-on"
		systemctl start nvidia-set-fpga-on.service
		break
	elif [ "$pin_val" == "0" ]; then
		# Pass
		:
	else
		echo "$FPGA0_RDY_PIN undefined: $pin_val"
		phosphor_log "$FPGA0_RDY_PIN undefined: $pin_val" $sevNot
	fi
	sleep 0.5
	((t++))
done

echo "HMC: $FPGA0_RDY_PIN starts with $pin_val"
phosphor_log "HMC: $FPGA0_RDY_PIN starts with $pin_val" $sevNot
exit 0
