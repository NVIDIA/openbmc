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

get_FPGA_READY() #(pin)
{
    gpioget `gpiofind "$FPGA0_RDY_PIN"`
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
