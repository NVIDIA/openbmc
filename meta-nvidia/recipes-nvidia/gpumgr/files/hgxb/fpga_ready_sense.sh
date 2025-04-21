#!/bin/sh
# sense fpga_ready status and start relevant systemd target

SERVICE="xyz.openbmc_project.State.Chassis"
INTERFACE="xyz.openbmc_project.State.Chassis"
PROPERTY="CurrentPowerState"
VALNAME="xyz.openbmc_project.State.Chassis"
object=`busctl tree $SERVICE --list | grep chassis`
state=`busctl get-property $SERVICE $object $INTERFACE $PROPERTY \
    | cut -d'"' -f2`
rc=$?
if [[ "$rc" == "0"  && "$state" == "${VALNAME}.PowerState.On" ]]; then
    # ready
    echo "fpga_ready is set"

    systemctl start nvidia-fpga-ready.target
else
    # not ready
    echo "fpga_ready is not set"

    systemctl start nvidia-fpga-notready.target
fi

