#!/bin/sh

#small function to execute desired command
run_command() {
    local cmd_output
    cmd_output="$($1 2>&1)"
    exit_code=$?
    echo "$cmd_output"
    return $exit_code
}

#nvidia-code-mgmt assigns this optional flag to decide if ignore jamplayer update
if [[ "$4" == "IGNORE" ]]; then
    #it's not jamplayer targeted update or UpdateAll, exits early
    logger -t jamplayer-update -p daemon.info "SKIP"
    exit 0
else
    logger -t jamplayer-update -p daemon.info "START"

    #strip 4K of signature
    tail -c +4097 $1 > /tmp/jamfile.jam

    #send to fw update status that the component is being transferred to the device
    busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} Update.1.0.TransferringToComponent xyz.openbmc_project.Logging.Entry.Level.Informational 3 'REDFISH_MESSAGE_ARGS' "$2,MAX10 CPLD" 'REDFISH_MESSAGE_ID' 'Update.1.0.TransferringToComponent' 'namespace' 'FWUpdate'
    result=$(run_command "jam-player -j /dev/jtag0 -aPROGRAM -dDO_REAL_TIME_ISP=1 /tmp/jamfile.jam")
    exit_code=$?

    #jam player will return code of 10 in the case where it throws the warning
    #becuase the chip is blank. In that case do the update without DO_REAL_TIME_ISP option
    if [ $exit_code -eq 10 ]; then
        result=$(run_command "jam-player -j /dev/jtag0 -aPROGRAM /tmp/jamfile.jam")
        exit_code=$?
    fi

    #if the update was not successful send the failed message to the update service
    if [ $exit_code -ne 0 ]; then
        busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} org.open_power.Logging.Error.TestError1 xyz.openbmc_project.Logging.Entry.Level.Warning 3 'REDFISH_MESSAGE_ARGS' "${result}" 'REDFISH_MESSAGE_ID' 'ResourceEvent.1.0.ResourceErrorsDetected' 'namespace' 'FWUpdate'
        logger -t jamplayer-update -p daemon.err "ERROR: ec = $exit_code"
        exit $exit_code
    fi

    #all worked fine. send the success message to the update service
    busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} Update.1.0.UpdateSuccessful xyz.openbmc_project.Logging.Entry.Level.Informational 3 'REDFISH_MESSAGE_ARGS' "MAX10 CPLD,$2" 'REDFISH_MESSAGE_ID' 'Update.1.0.UpdateSuccessful' 'namespace' 'FWUpdate'
    exit_code=$?

    logger -t jamplayer-update -p daemon.info "DONE"

    exit $exit_code
fi
