#!/bin/bash
source nvme_lib.sh

nvme_cpld_unbind 14 77
rc1=$?
nvme_cpld_unbind 15 77
rc2=$?
nvme_cpld_unbind 5 74
rc3=$?

# i2c8 is dedicated for the primary M.2 boot drive.

# i2c14, 7-bit-addr: 0x77 for E1.S slot0-3
[[ $rc1 -eq 0 ]] && nvme_cpld_bind 14 77

sleep 0.5

# i2c15, 7-bit-addr: 0x77 for E1.S slot4-7
[[ $rc2 -eq 0 ]] && nvme_cpld_bind 15 77

sleep 0.5

# i2c5, 7-bit-addr: 0x74 for an optional secondary M.2 on riser.
[[ $rc3 -eq 0 ]] && nvme_cpld_bind 5 74

sleep 3

# Restart FruDevice/EM since I2C muxes / logical buses just rebound.
if [ $rc1 -eq 0 ] || [ $rc2 -eq 0 ] || [ $rc3 -eq 0 ]; then
    # Rebind EEPROMs
    nvme_create_gb200_eeproms

    echo "Rescan devices exported by Entity Manager .."
    busctl call xyz.openbmc_project.EntityManager /xyz/openbmc_project/EntityManager xyz.openbmc_project.EntityManager ReScan

    echo "Rescan FruDevice .."
    busctl call xyz.openbmc_project.FruDevice /xyz/openbmc_project/FruDevice xyz.openbmc_project.FruDeviceManager ReScan
fi

echo "NVME CPLD probe completed."
