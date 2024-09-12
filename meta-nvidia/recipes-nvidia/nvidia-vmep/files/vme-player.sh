#!/bin/sh

#small function to execute desired command
run_command() {
    local cmd_output
    cmd_output="$($1 2>&1)"
    exit_code=$?
    echo "$cmd_output"
    return $exit_code
}

jtag_busy() {
    local busy_stat
    busy_stat=$(systemctl is-active vme-jtag-busy.target)
    if [ $busy_stat == "inactive" ]; then
        echo "0"
    else
        echo "1"
    fi
}

if [ $# -ne 3 ]; then
    echo "vme_player.sh: Too few parameters ($#), exiting"
    exit 1
fi

#Override for other platforms if required
setup_file="/usr/bin/setup_vme.sh"
cleanup_file="/usr/bin/cleanup_vme.sh"
file_name="/tmp/vmeplayer_${2}.vme"

# Find the CPLD descriptor to perform an update
if [[ "$3" == *"vme0"*  ]]; then
    #Allow VME0 updater to start
    systemctl start vme-jtag-busy.target

elif [[ "$3" == *"vme1"* ]]; then
    # Safety - prevent race
    sleep 2;
    busy_stat=`jtag_busy`
    if [[ "$busy_stat" == "1" ]]; then
        #Allow 60s for vme0 to finish
        echo " Waiting for vme0 to finish.."
        sleep 60;
    else
        break
    fi

    # 12 * 5s = 60s timeout
    retry=12 
    for i in $(seq 1 $retry); do
        busy_stat=`jtag_busy`
        if [[ "$busy_stat" == "1" ]]; then
            #Allow 60s for vme0 to finish
            echo " Waiting for vme0 to finish.."
            sleep 5;
        else
            break
        fi
    done

    #Timeout
    if [[ "$busy_stat" == "1" ]]; then
        echo "Timeout, couldn't update $3"
        exit 1
    fi
else 
    echo "VME descriptor type unknown"
    exit 1
fi


#strip 4K of signature
tail -c +4097 $1 > "$file_name"

#send to fw update status that the component is being transferred to the device
busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} Update.1.0.TransferringToComponent xyz.openbmc_project.Logging.Entry.Level.Informational 3 'REDFISH_MESSAGE_ARGS' "$2,LATTICE CPLD" 'REDFISH_MESSAGE_ID' 'Update.1.0.TransferringToComponent' 'namespace' 'FWUpdate'

if [ -f "$setup_file" ] && [ -x "$setup_file" ]; then
    result=$("$setup_file")
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        #send fw update task a message that update has failed
        busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} Update.1.0.TransferringToComponent xyz.openbmc_project.Logging.Entry.Level.Warning 3 'REDFISH_MESSAGE_ARGS' "${result}" 'REDFISH_MESSAGE_ID' 'ResourceEvent.1.0.ResourceErrorsDetected' 'namespace' 'FWUpdate'
        if [ -f "$cleanup_file" ] && [ -x "$cleanup_file" ]; then
            "$cleanup_file"
        fi
        exit $exit_code
    fi
fi
echo "Updating CPLD "$3" with image at "$file_name""
result=""
result=$(run_command "/usr/bin/ispvme -d /dev/jtag1 "$file_name"")
exit_code=$?
echo "exit code is $exit_code"

if [ $exit_code -ne 0 ]; then
    #send fw update task a message that update has failed
    busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} Update.1.0.UpdateFailed xyz.openbmc_project.Logging.Entry.Level.Warning 3 'REDFISH_MESSAGE_ARGS' "${result}" 'REDFISH_MESSAGE_ID' 'ResourceEvent.1.0.ResourceErrorsDetected' 'namespace' 'FWUpdate'
    if [ -f "$cleanup_file" ] && [ -x "$cleanup_file" ]; then
        "$cleanup_file"
    fi
    exit $exit_code
fi

if [ -f "$cleanup_file" ] && [ -x "$cleanup_file" ]; then
    "$cleanup_file"
fi

#all worked fine. send the success message to the update service
busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} Update.1.0.UpdateSuccessful xyz.openbmc_project.Logging.Entry.Level.Informational 3 'REDFISH_MESSAGE_ARGS' "LATTICE CPLD,$2" 'REDFISH_MESSAGE_ID' 'Update.1.0.UpdateSuccessful' 'namespace' 'FWUpdate'

exit $?
