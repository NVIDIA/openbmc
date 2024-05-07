#!/bin/bash


host_interface_nic=hostusb0
argument="$1"

if [ "$argument" = "boot-done" ]; then
    host_interface=$(busctl get-property xyz.openbmc_project.BIOSConfigManager /xyz/openbmc_project/bios_config/manager xyz.openbmc_project.BIOSConfig.Manager BaseBIOSTable --json=pretty | grep "RedfishHostInterface" -A 10 | grep "data")
    value=$(echo "$host_interface" | sed -n 's/.*"data" : "\([^"]*\)".*/\1/p')
    echo "BIOS Host Interface setting from bios attribute" $value
    if [ "$value" = "Disabled" ]; then
        echo "Disabling BIOS Host interface nic" $host_interface_nic
        ifconfig $host_interface_nic down
    fi
elif [ "$argument" = "boot-undone" ]; then
    echo "Enabling BIOS Host Interface" $host_interface_nic
    ifconfig $host_interface_nic up
else
    echo "Invalid argument passed to host interface control script"
fi
