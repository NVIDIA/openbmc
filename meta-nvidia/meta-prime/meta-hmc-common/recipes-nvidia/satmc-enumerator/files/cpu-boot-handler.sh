#!/bin/bash

argument="$1"

if [ "$argument" = "boot-done" ]; then
    echo "Received cpu $argument, restarting mctp-pcie-ctrl service."
    systemctl restart mctp-pcie-ctrl.service
elif [ "$argument" = "boot-undone" ]; then
    echo "Received cpu $argument, restarting mctp-pcie-ctrl service."
    systemctl restart mctp-pcie-ctrl.service
else
    echo "Invalid argument passed to cpu boot handler script"
fi
