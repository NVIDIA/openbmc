#!/bin/sh

# Only trigger the Discover System State once at just BMC boots for power restore
if [ `systemctl is-active phosphor-discover-system-state@0.service` != "active" ]; then
    systemctl start phosphor-discover-system-state@0.service
fi

is_host_req_on=`busctl get-property xyz.openbmc_project.State.Host /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.Host RequestedHostTransition | grep "Transition.On"`

if [ ! -z "$is_host_req_on" ];then
    busctl set-property xyz.openbmc_project.State.Host /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.Host RequestedHostTransition s xyz.openbmc_project.State.Host.Transition.Off
fi
