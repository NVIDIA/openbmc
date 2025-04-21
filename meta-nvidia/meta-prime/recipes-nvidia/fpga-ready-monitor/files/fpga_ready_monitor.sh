#!/bin/sh

#
# A number of GPU related services rely upon this on/off signal
#
get_FPGA_READY() #(pin)
{
    gpioget `gpiofind "FPGA_READY-I"`
}

# Main Loop
while true; do

	pin_val=`get_FPGA_READY`

	if [ "$pin_val" == "1" ]; then
		# ready
		echo "FPGA_READY is set"
		systemctl start nvidia-set-fpga-on.service
	else
		# not ready
		echo "FPGA_READY is not set"
		systemctl start nvidia-set-fpga-off.service
	fi

    sleep 0.1
    gpiomon --num-event=1 `gpiofind "FPGA_READY-I"`

    # debounce
    sleep 0.2
	
done
