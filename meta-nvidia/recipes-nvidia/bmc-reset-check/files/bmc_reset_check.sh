#!/bin/sh

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

# Check if kernel panic occurred
check_if_kernel_panic_occurred=`journalctl | grep "PStore dmesg-ramoops"`

# Get BMC reset reason from u-boot env
bmc_reset_reason=$(fw_printenv | grep reset_reason | cut -d "=" -f 2 | sed 's/_/ /g')
wdt=`echo $bmc_reset_reason | awk '{print $1}'`
reset_mode=`echo $bmc_reset_reason | awk '{print $2}'`

if [[ -n "$check_if_kernel_panic_occurred" ]]; then
    phosphor_log "BMC kernel panic occurred" $sevErr
elif [[ -n "$bmc_reset_reason" ]]; then
    if [[ "$wdt" == "WDT1" ]]; then
        phosphor_log "BMC normal reset" $sevNot
    else
        phosphor_log "BMC reset due to $wdt $reset_mode Reset" $sevWarn
    fi
else
    phosphor_log "BMC reset due to Unknown" $sevWarn
fi

exit 0
