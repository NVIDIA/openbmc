#!/bin/sh

timestamp=$(date +%s)

expect()
{
    res=`$2`
    if [ $? = $1 ]; then
        echo $3
        return 0
    else
        echo $4
        return -1
    fi
}

get_emmc_blk_devive()
{
    str_blk="$(/sbin/fdisk -l | grep "Disk" |grep "mmc")"
    eval 'arr=($str_blk)'
    echo -n ${arr[1]}|sed 's/://'
}

get_edua_size()
{
    local device_name=$1
    str_edua="$(mmc extcsd read $device_name | grep -A 1 "\[MAX_ENH_SIZE_MULT]:")"
    eval "arr=($str_edua)"
    element="KiB"
    index=-1
    for i in "${!arr[@]}";
    do
        if [[ "${arr[$i]}" = "${element}" ]]; then
	    index=$i
	    size=${arr[$index-1]}
	    echo $size
	    break
	fi
    done
}

get_secure_support()
{
    local device_name=$1
    str="$(mmc extcsd read $device_name | grep "SEC_FEATURE_SUPPORT")"
    echo $str
}

secure_erase()
{
    local device_name=$1
    local start=$2
    local size=$3
    str="$(mmc erase secure-erase $start $size $device_name |grep -E "Succeed|Fail")"
    echo $str
}

get_fw_version()
{
    local device_name=$1
    str_fw_ver="$(mmc extcsd read $device_name | grep -A 1 "\Firmware Version")"
    eval "arr=($str_fw_ver)"
    echo ${arr[3]}
}

emmc_write(){
    local partition=$1
    echo -n $2 > $partition
}

emmc_write_all_partition(){
    parts="$(df |grep $1)"
    while IFS= read -r line
    do
        eval "arr=($line)"
        emmc_write ${arr[0]} $2
        echo "Write to "${arr[0]}
    done <<< "$parts"
}

emmc_read(){
    local partition=$1
    local size=$2
    out="$(dd if=/dev/mmcblk0p3 count=$2 bs=1)"
    echo $partition: $out
}

emmc_read_all_partition(){
    parts="$(df |grep $1)"
    while IFS= read -r line
    do
        eval "arr=($line)"
        emmc_read ${arr[0]} $2
    done <<< "$parts"
}

emmc_reboot_while_write(){
    local partition="${1}p${2}"
    echo "Rewrite a lengthy string to the partition $partition repeatedly"
    str=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | dd bs=1 count=200 2>/dev/null)
    yes $str > $partition&
    sleep 10
    echo "Reboot during write process"
    reboot
}

get_partition()
{
    parts="$(/sbin/fdisk -l |grep $1)"
    while IFS= read -r line
    do
        eval "arr=($line)"
        echo ${arr[0]} ${arr[6]}
    done <<< "$parts"
}

format_partitions()
{
    local number=$1
    echo "Formatting /dev/mmcblk0p${number}"
    mke2fs -t ext4 /dev/mmcblk0p${number}
    sleep 1
    echo "Enable journal /dev/mmcblk0p${number}"
    tune2fs -o journal_data /dev/mmcblk0p${number}
}

get_mountpoint()
{
    parts="$(df |grep $1)"
    while IFS= read -r line
    do
        eval "arr=($line)"
        #printf "\rPartition : %20s mounted on %20s\n" ${arr[0]} ${arr[5]}
        echo ${arr[5]}
    done <<< "$parts"
}

dd_all_partition()
{
    dd if=/dev/urandom of=$1 bs=$2 count=1
}

dd_all_emmc()
{
    i=0
    while [ $i -lt 3596 ];
    do
            dd if=/run/initramfs/dd_emmc.image of=/dev/mmcblk0 count=2097152 bs=1 seek=$[$i*524288]
            i=$[$i+1]
    done
}

delete_partition()
{
    local device=$1
    local part=$2
    umount /mnt/mmcblk0p${part}
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | /sbin/fdisk $device
    d # del partition
    $part # primary partition
    w #save changes
EOF
}

corrupt_fs()
{
    local part=$1
    umount /mnt/mmcblk0p${part}
    dd if=/dev/urandom of=/dev/mmcblk0p${part} count=1048576 bs=1
}
case $1 in
    get_emmc_blk_devive) "$@"; exit;;
    get_edua_size) "$@"; exit;;
    get_fw_version) "$@"; exit;;
    get_partition) "$@"; exit;;
    emmc_write_all_partition) "$@"; exit;;
    emmc_read_all_partition) "$@"; exit;;
    emmc_reboot_while_write) "$@"; exit;;
    get_secure_support) "$@"; exit;;
    secure_erase) "$@"; exit;;
    get_mountpoint) "$@"; exit;;
    delete_partition) "$@"; exit;;
    format_partitions) "$@"; exit;;
    corrupt_fs) "$@"; exit;;
esac
