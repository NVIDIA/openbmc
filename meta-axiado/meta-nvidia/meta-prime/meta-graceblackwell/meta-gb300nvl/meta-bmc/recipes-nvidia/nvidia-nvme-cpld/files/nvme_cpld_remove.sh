#!/bin/bash
source nvme_lib.sh

# Unbind E1.S / 2nd M.2 MUX
nvme_cpld_unbind 5 74 force
nvme_cpld_unbind 15 77 force
nvme_cpld_unbind 14 77 force

echo "NVME CPLD remove completed."
