#!/bin/sh

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

# BMC Reset Reason Documentation
# This script identifies and logs BMC reset events based on reset_reason from u-boot
#
# Reset Scenarios and Expected Variable Values:
# +-------------------+----------+------------+---------------------------------+-----------------------------------+
# |     uboot env     |   wdt    | reset_mode |           Description           |                Log                |
# +-------------------+----------+------------+---------------------------------+-----------------------------------+
# | Power_On          | N/A      | N/A        | Cold reboot                     | BMC power-on reset                |
# +-------------------+----------+------------+---------------------------------+-----------------------------------+
# | WDT1_SOC          | WDT1     | SOC        | Warm reboot triggered by user   | BMC normal reset                  |
# | WDT1_FULL         |          | FULL       |                                 |                                   |
# | WDT1_ARM          |          | ARM        |                                 |                                   |
# | WDT1_SW           |          | SW         |                                 |                                   |
# +-------------------+----------+------------+---------------------------------+-----------------------------------+
# | WDT[2-8]_SOC      | WDT[2-8] | SOC        | Warm reboot triggered by other  | BMC reset due to $wdt $reset_mode |
# | WDT[2-8]_FULL     |          | FULL       | watchdog timer                  | Reset                             |
# | WDT[2-8]_ARM      |          | ARM        |                                 |                                   |
# | WDT[2-8]_SW       |          | SW         |                                 |                                   |
# +-------------------+----------+------------+---------------------------------+-----------------------------------+
# | N/A               | WDT1     | SOC        | Reboot due to kernel watchdog   | BMC reset due to kernel watchdog  |
# |                   |          |            | timeout or panic/exception,     |                                   |
# |                   |          |            | which is checked by             | --------------------------------- |
# |                   |          |            | "PStore dmesg-ramoops" in the   | BMC kernel panic occurred         |
# |                   |          |            | journal                         |                                   |
# +-------------------+----------+------------+---------------------------------+-----------------------------------+
# | N/A               | N/A      | N/A        | Reboot due to panic/exception,  | BMC kernel panic occurred         |
# |                   |          |            | which is checked by             |                                   |
# |                   |          |            | "PStore dmesg-ramoops" in the   |                                   |
# |                   |          |            | journal                         |                                   |
# +-------------------+----------+------------+---------------------------------+-----------------------------------+
#
# Note:
# - The Kernel_WDT reason has not been implemented yet in uboot env.

# Check if kernel panic occurred
check_if_kernel_panic_occurred=$(journalctl -b | grep "PStore dmesg-ramoops")
check_if_kernel_wdt_timeout_occurred=$(cat /var/lib/systemd/pstore/dmesg-ramoops-0 | grep "watchdog pretimeout event")

# Get BMC reset reason from u-boot env
bmc_reset_reason=$(fw_printenv | grep reset_reason | cut -d "=" -f 2 | sed 's/_/ /g')
wdt=$(echo $bmc_reset_reason | awk '{print $1}')
reset_mode=$(echo $bmc_reset_reason | awk '{print $2}')

if [[ -n "$check_if_kernel_wdt_timeout_occurred" ]]; then
    phosphor_log "BMC kernel watchdog timeout occurred" $sevErr
elif [[ -n "$check_if_kernel_panic_occurred" ]]; then
    phosphor_log "BMC kernel panic occurred" $sevErr
elif [[ -n "$bmc_reset_reason" ]]; then
    if [[ $bmc_reset_reason == "Power On" ]]; then
        phosphor_log "BMC power-on reset" $sevNot
    elif [[ "$wdt" == "WDT1" ]]; then
        phosphor_log "BMC normal reset" $sevNot
    else
        phosphor_log "BMC reset due to $wdt $reset_mode Reset" $sevWarn
    fi
else
    phosphor_log "BMC reset due to Unknown" $sevWarn
fi

exit 0
