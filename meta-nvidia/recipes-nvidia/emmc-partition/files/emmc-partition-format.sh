#!/bin/sh

#This script will do EMMC partitioning/format/mounting.
#This flow wiill be opt-in/out based on u-boot env "emmc" enable/disable
#This script performs theses tasks at boot-up:
# 1.Check if EMMC is initialized by driver.
# 2.Program EUDA size, and check if EUDA is activated [the real disk size is equal to EUDA size].
# 3.Partition EMMC based on create_partitions.sh, this will be specific on platform.
# 4.Format/Mount EMMC partitions to mount points based on /usr/share/emmc/emmc-mount.conf
#Return Code:
# 0 -> Success
# 1 -> EMMC init fail
# 2 -> EMMC is not enabled
# 3 -> EUDA failed to programmed
# 4 -> EUDA is not activated
# 5 -> Partition failed
# 6 -> Format failed
# 7 -> Mount failed

EMMC_DEVICE=$1

echo $EMMC_DEVICE >> /dev/console

dbus_log()
{
    # mtype (severity level) options:
    # Emergency/Alert/Critical/Error/Warning/Notice/Informational/Debug
    local mtype=$1
    local message=$2
    busctl call xyz.openbmc_project.Logging \
                /xyz/openbmc_project/logging \
                xyz.openbmc_project.Logging.Create \
                Create ssa{ss} \
                "$message" \
                xyz.openbmc_project.Logging.Entry.Level.$mtype \
                0
}

euda_config()
{
    local device_name=$1
    local expected_size=$2
    euda_config_return=0
    str_euda="$(mmc extcsd read /dev/$device_name | grep -A 1 "\[MAX_ENH_SIZE_MULT]:")"
    get_euda_size "$str_euda"
    max_euda_size=$size

    str_euda="$(mmc extcsd read /dev/$device_name | grep -A 1 "\[ENH_SIZE_MULT]:")"
    get_euda_size "$str_euda"
    programmed_euda_size=$size
    programmed_euda_size_in_byte=$((programmed_euda_size*1024))

    dbus_log Debug "Max Enhanced Area Size [MAX_ENH_SIZE_MULT]: ${max_euda_size} KiB"
    dbus_log Debug "EUDA size [ENH_SIZE_MULT]: ${programmed_euda_size} KiB"

    if [ $programmed_euda_size -eq 0 ]; then
        echo "EUDA is not programmed !!! Programming EUDA now."
        mmc enh_area set -y 0 $max_euda_size /dev/$device_name
        #Check EUDA size if it is programmed ok.
        str_euda="$(mmc extcsd read /dev/$device_name | grep -A 1 "\[ENH_SIZE_MULT]:")"
        get_euda_size "$str_euda"
        programmed_euda_size=$size
        programmed_euda_size_in_byte=$((programmed_euda_size*1024))
        dbus_log Debug "EUDA size after configured: ${programmed_euda_size} KiB"

        if [ "$programmed_euda_size" != "$max_euda_size" ]; then
            #EUDA size is failed to program
            msg="EUDA failed to program."
            echo "${msg}"
            dbus_log Error "${msg}"
            euda_config_return=3
        else
            #EUDA is programmed but need activated by one power-on-reset.
            echo "EUDA is programmed, but not activated, power-on-reset EMMC needed to activate EUDA."
            dbus_log Warning "Power cycle to activate EUDA."
            euda_config_return=4
        fi
    elif [ "$programmed_euda_size_in_byte" != "$expected_size" ]; then
        echo "EUDA is programmed, but not activated, power-on-reset EMMC needed to activate EUDA."
        dbus_log Warning \
                 "EUDA size doesn't match expected size (${expected_size}). Try rebooting again."
        euda_config_return=4
    else
        echo "EUDA is programmed and activated."
        echo "Partition and format for device: $device_name"
	    create_partitions $device_name
        if [ $create_partitions_return == 1 ]; then
            #Partition failed
            euda_config_return=5
        else
            #Partition ok, mount partitions.
	        mount_partitions $device_name
            if [ $mount_partitions_return == 1 ]; then
                #Filesystem wrong
                euda_config_return=6
            elif [ $mount_partitions_return == 2 ]; then
                #Mount point wrong
                euda_config_return=7
            fi
	    fi
    fi
}

get_disk_size()
{
    str=$1
    eval "arr=($str)"
    element="bytes,"
    index=-1
    for i in "${!arr[@]}";
    do
        if [[ "${arr[$i]}" = "${element}" ]]; then
	    index=$i
	    size=${arr[$index-1]}
	    return $size
	    break
	fi
    done
}

get_disk_sectors()
{
    str=$1
    eval "arr=($str)"
    element="sectors"
    index=-1
    for i in "${!arr[@]}";
    do
        if [[ "${arr[$i]}" = "${element}" ]]; then
	    index=$i
	    size=${arr[$index-1]}
	    return $size
	    break
	fi
    done
}

get_euda_size()
{
    str=$1
    eval "arr=($str)"
    element="KiB"
    index=-1
    for i in "${!arr[@]}";
    do
        if [[ "${arr[$i]}" = "${element}" ]]; then
	    index=$i
	    size=${arr[$index-1]}
	    return $size
	    break
	fi
    done
}

format_partitions()
{
    local device_name=$1
    local number=$2
    local partition=/dev/${device_name}p${number}
    local msg="Formatting ${partition}"
    echo $msg
    dbus_log Debug "${msg}"
    mke2fs -t ext4 ${partition}
    sleep 1
    echo "Enable journal ${partition}"
    tune2fs -o journal_data ${partition}
    sleep 1
}

check_partition()
{
    local device_name=$1
    local retry=$2
    partition_check_result="ok"
    #load partition mapping
    mount_map=$(cat /usr/share/emmc/emmc-mount.conf)    

    for (( i=0; i<$retry; i++)); do
        echo "Try $i checking partition with mount map."
	partition_check_result="ok"
        while IFS= read -r l
        do
            eval "arr=($l)"
            partition_number=${arr[0]}
            partition_str=/dev/${device_name}p${partition_number}
            if [ ! -b "$partition_str" ]; then
                local msg="Partition ${partition_str} not exist."
                echo $msg
                dbus_log Error "${msg}"
                partition_check_result="fail"
            fi
        done <<< "$mount_map"
        if [ "$partition_check_result" == "ok" ]; then
            break
        fi
        sleep 3
    done
}

create_partitions()
{
    local device_name=$1
    local partition_number=0
    need_partitioning="no"
    create_partitions_return=0

    #check partition
    check_partition $device_name 5

    if [ "$partition_check_result" == "ok" ]; then
        echo Partitions in ${device_name} exists, no need to do partitioning.
    else
        echo Partitions in ${device_name} does not exists
        dbus_log Debug "create partition ${device_name}"
	    str=$(create-partition.sh $device_name)
        #check created partitions
        check_partition $device_name 5

        if [ "$partition_check_result" == "fail" ]; then
            echo Partitioning ${device_name} failed.
            create_partitions_return=1
        else
            echo Partitioning ${device_name} success.
            #Format partition with ext4 file system with journal enable
            #Partition number come from emmc-mount.conf
            mount_map=$(cat /usr/share/emmc/emmc-mount.conf)

            while IFS= read -r l
            do
                eval "arr=($l)"
                partition_number=${arr[0]}
                str=$(format_partitions $device_name $partition_number)
            done <<< "$mount_map"
        fi
    fi
}

mount_partitions()
{
    local device_name=${1}
    local partition_name="/dev/${1}p"
    mount_map=$(cat /usr/share/emmc/emmc-mount.conf)
    mount_partitions_return=0
    while IFS= read -r l
    do
        eval "arr=($l)"
        partition_number=${arr[0]}
        mount_point=${arr[1]}
        if [ $partition_number -ne 4 ]; then
            dbus_log Debug "Mount ${partition_name}${partition_number} on ${mount_point}"
            mkdir -p $mount_point
            mount -t auto $partition_name${partition_number} $mount_point
            if mount | grep "$mount_point"; then
                    echo "Mounted $mount_point"
            else
                echo "Cannot find mount point: " $mount_point
                echo "Try to fix the filesystem for $partition_name${partition_number}"
                dbus_log Warning "Try fsck to fix mounting failure."
                fsck -y $partition_name${partition_number}
                mount -t auto $partition_name${partition_number} $mount_point
                if mount | grep "$mount_point"; then
                    echo "Mounted $mount_point"
                else
                    #Re-formate and try to mount again
                    dbus_log Warning "fsck failed to recover -> try formatting the partition."
                    format_partitions $device_name $partition_number
                    mount -t auto $partition_name${partition_number} $mount_point
                fi
            fi
        fi
    done <<< "$mount_map"

    #check fs type and mount point
    sleep 2
    while IFS= read -r l
    do
        eval "arr=($l)"
        partition_number=${arr[0]}
        mount_point=${arr[1]}
        str=$(df -T |grep "$device_name"p"$partition_number")
        eval "str_arr=($str)"
        if [ "${str_arr[1]}" != "ext4" ]; then
            local msg="Partition ${partition_number} FS wrong. Expect ext4"
            echo $msg
            dbus_log Error "${msg}"
            mount_partitions_return=1
        elif [ "${str_arr[6]}" != "${arr[1]}" ]; then
            local msg="Partition ${partition_number} mount point wrong."
            echo $msg
            dbus_log Error "${msg}"
            mount_partitions_return=2
        fi
	tmpfile="${mount_point}/selftest_tmpfile"
	if ! echo "selftest" > ${tmpfile}; then
            local msg="R/W selftest on mountpoint ${mount_point} failed. Recover FS."
            echo $msg
            dbus_log Error "${msg}"
	    local partition=$partition_name${partition_number}
	    if mountpoint ${mount_point}; then
		umount ${mount_point}
	    fi
	    mke2fs -t ext4 ${partition}
	    tune2fs -o journal_data ${partition}
            mount -t auto ${partition} ${mount_point}
	fi
	rm -f ${tmpfile}
    done <<< "$mount_map"
}

secure_erase()
{
    local device_name=$1
    local from_sector=$2
    local to_sector=$3
    local retry=$4

    for (( i=0; i<$retry; i++)); do
        echo "Try $i for secure erase."
        str=$(mmc erase secure-erase $from_sector $to_sector $device_name |grep "Secure Erase Succeed")
        dbus_log Debug "Secure Erase result: ${str}"
        if [ "$str" != "" ];then
            echo "Emmc Secure Erase Succeed!"
            secure_erase_return=0
            return
        fi
    done
    echo "Emmc Secure Erase Failed!"
    secure_erase_return=1
}

#Check if emmc is initialized by driver
if [ ! -b "/dev/${EMMC_DEVICE}" ]; then
    local msg="Cannot find out emmc. Exit without partitioning."
    echo $msg
    dbus_log Error "${msg}"
    exit 1
else
    echo "Found emmc: "$EMMC_DEVICE
fi

str_fdisk="$(fdisk -l |grep "/dev/$EMMC_DEVICE.*bytes")"
get_disk_size "$str_fdisk"
disk_size=$size
get_disk_sectors "$str_fdisk"
disk_sectors=$size
dbus_log Debug "(fdisk) size=${disk_size}, sectors=${disk_sectors}"

#Get u-boot env to check if need to do secure erase
emmc_uboot_env=$(fw_printenv emmc_secure_erase |grep "yes\|no")
secure_erase_need=${emmc_uboot_env#*=}
dbus_log Debug "eMMC uboot env: ${emmc_uboot_env}"

#Get u-boot env to check if need to do secure erase of a particular partition
emmcPartition_uboot_env=$(fw_printenv emmc_secure_erase_partition | awk -F '=' '{print $NF}')
dbus_log Debug "eMMC uboot env for specific partition: ${emmcPartition_uboot_env}"

if [ "$secure_erase_need" == "yes" ]; then
    echo "Need to perform eMMC Secure Erase."
    #Unset the uboot env first to avoid multiple secure erase
    to_sector=$((disk_sectors-1))
    secure_erase /dev/mmcblk0 0 $to_sector 3
    if [ $secure_erase_return == 0 ]; then
        fw_setenv emmc_secure_erase
    fi
fi

if [ -n "$emmcPartition_uboot_env" ]; then
    partition_line=$(cat /usr/share/emmc/emmc-mount.conf | grep "$emmcPartition_uboot_env")
    partition_number=$(echo "$partition_line" | awk '{print $1}')
    partition=/dev/mmcblk0p"$partition_number"
    if mountpoint "$emmcPartition_uboot_env"; then
        umount $emmcPartition_uboot_env
    fi
    mke2fs -t ext4 $partition
    tune2fs -o journal_data $$partition
    fw_setenv emmc_secure_erase_partition
fi

euda_config $EMMC_DEVICE $disk_size
echo "Finished NVIDIA emmc partition Service."
exit $euda_config_return

