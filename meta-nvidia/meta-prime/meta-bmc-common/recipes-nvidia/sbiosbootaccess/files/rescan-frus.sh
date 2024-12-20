#!/bin/bash

rescan_fru_device()
{
    # Rescan I2C for FRUs and rescan entity manager
    busctl call xyz.openbmc_project.FruDevice /xyz/openbmc_project/FruDevice xyz.openbmc_project.FruDeviceManager ReScanBus q 14
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Failed to issue rescan to bus 14 with xyz.openbmc_project.FruDeviceManager"
        return 1
    fi
    busctl call xyz.openbmc_project.FruDevice /xyz/openbmc_project/FruDevice xyz.openbmc_project.FruDeviceManager ReScanBus q 15
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Failed to issue rescan to bus 15 with xyz.openbmc_project.FruDeviceManager"
        return 1
    fi

    echo "[INFO] xyz.openbmc_project.FruDeviceManager rescan completed"
    return 0
}


rescan_entity_manager()
{
    busctl call xyz.openbmc_project.EntityManager /xyz/openbmc_project/EntityManager xyz.openbmc_project.EntityManager ReScan
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERROR] Failed to issue rescan to xyz.openbmc_project.EntityManager"
        return 1
    fi
    echo "[INFO] xyz.openbmc_project.EntityManager rescan completed"
    return 0
}

#### Main ####

rescan_fru_device
rc=$?
if [[ $rc -ne 0 ]]; then
    exit 1
fi

# Allow time for FruDevice service to stabilize
sleep 3

echo "[INFO] CPU_BOOT_DONE Fru Rescan completed"
exit 0
