#!/bin/bash

# Inherit Logging libraries
source /etc/default/nvidia_event_logging.sh

WORK_DIR=/run/initramfs/rw/work

check_fs_recovery()
{
    # Check for previous recovery
    recovery=$(fw_printenv | grep dataflashrecovery | sed 's/.*=//')
    if [ "$recovery" == "yes" ];
    then
        sleep 10 # wait for log service stratup
        echo "Creating Redfish log for flash auto recovery"
        message_arg="Management Controller Flash,Data Corruption"
        busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} \
                ResourceEvent.1.0.ResourceErrorsCorrected xyz.openbmc_project.Logging.Entry.Level.Informational 2 \
                REDFISH_MESSAGE_ID ResourceEvent.1.0.ResourceErrorsCorrected \
                REDFISH_MESSAGE_ARGS "$message_arg"
        if [ $? -eq 0 ]; then
            fw_setenv dataflashrecovery
        else
            echo "Failed to create Redfish log for auto recovery"
        fi
    fi
}

#######################################
# Confirm mountpoint from given path
#
# ARGUMENTS:
#   arg1 - Path to check mountpoint
# RETURN:
#   0 Success, path is mounted
#   1 Error, path not mounted
confirm_mountpoint()
{
    mount_path=$1
    if ! mountpoint $mount_path &> /dev/null;
    then
        mountpoint_fail="[ERROR] Mount failure at $mount_path"
        echo "$mountpoint_fail"
        phosphor_log "$mountpoint_fail" $sevErr
        return 1
    fi
    return 0    
}

#######################################
# Confirm filesytems are mounted
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Success, critical filesystems are mounted
#   1 Error, /run/initramfs/rw not mounted
#   2 Error, /var/lib/logging not mounted
check_rw_filesystems()
{
    check_fs_recovery

    confirm_mountpoint /run/initramfs/rw
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "Erasing /dev/mtd6 partition on detection of corruption"
        flash_eraseall -q /dev/mtd6
        fw_setenv dataflashrecovery yes
        # Need time here to ensure any background uboot-env (flash) update finishes before reboot
        sleep 5
        systemctl reboot --force
        return 1
    fi

    confirm_mountpoint /var/lib/logging
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "Erasing /dev/mtd7 partition on detection of corruption"
        flash_eraseall -q /dev/mtd7
        fw_setenv dataflashrecovery yes
        # Need time here to ensure any background uboot-env (flash) update finishes before reboot
        sleep 5
        systemctl reboot --force
        return 2
    fi

    # All mountpoints confirmed
    return 0
}

#######################################
# Determine if Management Controller has booted in ROFS only
# If so, recommend factory reset 
#
# ARGUMENTS:
#   None
# RETURN:
#   0 Success, Management Controller did not boot in ROFS (Read-Only mode)
#   1 Error, Management Controller booted in ROFS (Read-Only mode)
check_rofs()
{
    if [ -d $WORK_DIR ]
    then
        cd $WORK_DIR
        if [ ! -d work ]
        then
            if ! mkdir work &> /dev/null
            then
                rwfsfull="[ERROR] No space left on rwfs. Management Controller booted in read only mode. Perform Factory reset to recover read write functionality. Please recover before flashing Management Controller." 
                phosphor_log "$rwfsfull" $sevErr
                echo $rwfsfull
                return 1
            fi
        fi
    else
        echo "Could not find work directory, $WORK_DIR"
        return 1
    fi
    return 0
}
