#!/bin/bash


host_interface_nic=hostusb0
argument="$1"

if [ "$argument" = "boot-done" ]; then
    host_interface=$(busctl get-property xyz.openbmc_project.BIOSConfigManager /xyz/openbmc_project/bios_config/manager xyz.openbmc_project.BIOSConfig.Manager BaseBIOSTable --json=pretty | grep "RedfishHostInterface" -A 10 | grep "data")
    value=$(echo "$host_interface" | sed -n 's/.*"data" : "\([^"]*\)".*/\1/p')
    echo "BIOS Host Interface setting from bios attribute" $value
    if [ "$value" = "Disabled" ]; then
        echo "Disabling BIOS Host interface nic" $host_interface_nic
        ip link set "$host_interface_nic" down
    fi
    busctl set-property xyz.openbmc_project.State.Host0 /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.OperatingSystem.Status OperatingSystemState s xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.Standby
elif [ "$argument" = "boot-undone" ]; then
    echo "Enabling BIOS Host Interface" $host_interface_nic
    ip link set "$host_interface_nic" up
    busctl set-property xyz.openbmc_project.State.Host0 /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.OperatingSystem.Status OperatingSystemState s xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.Inactive
else
    echo "Invalid argument passed to host interface control script"
fi
