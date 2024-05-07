#!/bin/sh

source /usr/bin/system_state_files.sh

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

# Get platform variables
source /etc/default/platform_var.conf

# Update chassis status based on SYS_PWROK pin

CHASSIS_SERVICE="xyz.openbmc_project.State.Chassis"
CHASSIS_INTERFACE="xyz.openbmc_project.State.Chassis"
CHASSIS_STATE_PROPERTY="CurrentPowerState"
CHASSIS_TRANSITION_PROPERTY="RequestedPowerTransition"

HOST_SERVICE="xyz.openbmc_project.State.Host"
HOST_INTERFACE="xyz.openbmc_project.State.Host"
HOST_TRANSITION_PROPERTY="RequestedHostTransition"

HOST_VALNAME="xyz.openbmc_project.State.Host"
CHASSIS_VALNAME="xyz.openbmc_project.State.Chassis"

#
# Exchange RUN_POWER_PG via a tmp file with powerctrl.sh
# power_status_monitor.sh captures the real GPIO line and mirrors it's
# status to the file.
#

rm_exists() #Remove a file if it exists (file_name)
{   
    local file=$1
    if test -f "${file}" 
    then     
        rm $file 
    fi
}

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

rm_exists $SYS_DISCOVERY_FILE
pwrsts_pin="RUN_POWER_PG-I"
sysrst_pin="SYS_RST_IN_L-O"
pci_mux_sel_pin="PCI_MUX_SEL-O"
chassis_object=`busctl tree $CHASSIS_SERVICE --list | grep chassis`
host_object=`busctl tree $HOST_SERVICE --list | grep host`
on_edge=0

pin_val=`get_gpio "$pwrsts_pin"`
echo "Power Status Monitor starts with RUN_POWER_PG-I = $pin_val"

# Check if the previous power on was interrupted before it could complete
# (this would leave the host in reset)
if [ "$pin_val" == "1" ]; then
        SYS_RST_OUT=$(get_gpio "SYS_RST_OUT_L-I")
        if [ "$SYS_RST_OUT" == "0" ]; then
		echo "WARNING: Incomplete host power up detected"
		# Pulse SHDN_FORCE so FPGA honors RUN_POWER state change
		set_gpio SHDN_FORCE_L-O 0
		sleep 0.5
		set_gpio SHDN_FORCE_L-O 1

		sleep 0.5

		#set_gpio RUN_POWER_EN-O 0
		echo 0 > /sys/class/gpio/gpio${sysfs_run_power}/value

		# The host was not really on, so clearing pin_val
                pin_val=0
	fi
fi

echo $pin_val > $RUN_POWER_PG_FILE

if [ "$pin_val" == "1" ]; then
    pin_stat="On"
    # Create chassis-on file
    # Creation of this file needs to happend before systemd-notify
    touch $SYS_DISCOVERY_FILE
else
    pin_stat="Off"
    echo "SYS RST initial value is: " $(get_gpio "SYS_RST_OUT_L-I")
    #Ensure SYS_RST is asserted when host is off
    set_gpio "$sysrst_pin" 0    
fi

#
# We set chassis state here just to ensure that everything is synced for phosphor-discover-system-state
# which will happen as soon as we systemd-notify ready
#
echo "Setting $CHASSIS_SERVICE $chassis_object $CHASSIS_INTERFACE $CHASSIS_STATE_PROPERTY to ${CHASSIS_VALNAME}.PowerState.${pin_stat}"
# Set current state in phosphor-chassis-state-manager
busctl set-property $CHASSIS_SERVICE $chassis_object $CHASSIS_INTERFACE \
    $CHASSIS_STATE_PROPERTY s ${CHASSIS_VALNAME}.PowerState.${pin_stat}

# Notify systemd that service has started
systemd-notify --ready --status="Entering RUN_POWER_PG-I monitor Loop"

# Main
while true; do

    pin_val=`get_gpio "$pwrsts_pin"`
    echo $pin_val > $RUN_POWER_PG_FILE

    if [ "$pin_val" == "1" ]; then

        # Create chassis-on file
        touch $SYS_DISCOVERY_FILE

        echo "Setting $CHASSIS_SERVICE $chassis_object $CHASSIS_INTERFACE $CHASSIS_TRANSITION_PROPERTY to ${CHASSIS_VALNAME}.Transition.On"
        # Signal transition to phosphor-chassis-state-manager
	    busctl set-property $CHASSIS_SERVICE $chassis_object $CHASSIS_INTERFACE \
            $CHASSIS_TRANSITION_PROPERTY s ${CHASSIS_VALNAME}.Transition.On

        echo "Setting $HOST_SERVICE $host_object $HOST_INTERFACE $HOST_TRANSITION_PROPERTY to ${HOST_VALNAME}.Transition.On"
        # Signal transition to phosphor-host-state-manager
        busctl set-property $HOST_SERVICE $host_object $HOST_INTERFACE \
            $HOST_TRANSITION_PROPERTY s ${HOST_VALNAME}.Transition.On

        # Set PCI Mux on IOX expander
        set_gpio "$pci_mux_sel_pin" 1

        # Don't do this on the first fall through this logic on service start
        # It causes an unexpected and unnecessary MCTP/GPU restart
        if [ "$on_edge" == "1" ]; then
            phosphor_log "Host Powered ON." $sevNot
        fi

    else
        #
        # Write to these as quickly as possible
        #

        # Assert SYS_RST_IN_L-O
        # Should also be asserted by SHUTDOWN OK monitor
        set_gpio "$sysrst_pin" 0
     
        echo "Set SYS_RST_IN_L-O=0"        

        echo "Setting $CHASSIS_SERVICE $chassis_object $CHASSIS_INTERFACE $CHASSIS_TRANSITION_PROPERTY to ${CHASSIS_VALNAME}.Transition.Off"
        # Signal transition to phosphor-chassis-state-manager
	    busctl set-property $CHASSIS_SERVICE $chassis_object $CHASSIS_INTERFACE \
            $CHASSIS_TRANSITION_PROPERTY s ${CHASSIS_VALNAME}.Transition.Off

        # Remove chassis-on file
        rm_exists $SYS_DISCOVERY_FILE

        #
        # Delete Redfish Host Interface user
        #
        echo "Removing Redfish Host Interface User"
        /bin/bash /usr/bin/delete-hi-user.sh

    fi

    # Wait for next transition
    gpiomon --num-event=1 `gpiofind "$pwrsts_pin"`
    on_edge=1

done
