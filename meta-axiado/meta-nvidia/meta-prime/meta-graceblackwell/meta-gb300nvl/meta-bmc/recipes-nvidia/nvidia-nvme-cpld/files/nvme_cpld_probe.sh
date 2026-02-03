#!/bin/bash
source nvme_lib.sh

nvme_cpld_unbind 14 77
rc1=$?
nvme_cpld_unbind 15 77
rc2=$?

# i2c8 is dedicated for the primary M.2 boot drive.

# i2c14, 7-bit-addr: 0x77 for E1.S slot0-3
[[ $rc1 -eq 0 ]] && nvme_cpld_bind 14 77

# i2c15, 7-bit-addr: 0x77 for E1.S slot4-7
[[ $rc2 -eq 0 ]] && nvme_cpld_bind 15 77

echo "NVME CPLD probe completed."
