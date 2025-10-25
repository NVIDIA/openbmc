#!/bin/bash

argument="$1"

if [ "$argument" = "boot-done" ]; then
    echo "Received cpu $argument, restarting mctp-pcie-ctrl service."
    systemctl restart mctp-pcie-ctrl.service
    busctl set-property xyz.openbmc_project.State.Host0 /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.OperatingSystem.Status OperatingSystemState s xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.StandBy

elif [ "$argument" = "boot-undone" ]; then
    echo "Received cpu $argument, restarting mctp-pcie-ctrl service."
    systemctl restart mctp-pcie-ctrl.service
    busctl set-property xyz.openbmc_project.State.Host0 /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.OperatingSystem.Status OperatingSystemState s xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.Inactive

else
    echo "Invalid argument passed to cpu boot handler script"
fi
