#!/bin/bash

# config 
source i2c-slave-config.sh

# Get platform variables
source /etc/default/platform_var.conf

### globals

# RO EEPROM header bytes (see GB200 NVL Firmware EAS Specification)
# 0x00: HMC Boot Complete
# 0x01-0x0F: data_array
declare -a data_array
# 0x10-0x17: reserved
# 0x18: Spec Version
I2C_DIRECT_APP_VERSION_OFFSET=24
I2C_DIRECT_APP_VERSION_SIZE=1
I2C_DIRECT_APP_VERSION='\x05'

fs_sanity=false
rwfs_full=false
rwfs_full_counter=0
script_start=$(date +%M)
log_partition=/dev/mmcblk0p3

BMC_IP=172.31.13.241
HMC_IP=172.31.13.251

findmtd() {
	m=$(grep -xl "$1" /sys/class/mtd/*/name)
	m=${m%/name}
	m=${m##*/}
	echo $m
}

function i2c_slave_create()
{
    ## Create only if the slave does not exists 
    if [ ! -f "$I2C_SLAVE_FILE" ]; then
        echo $I2C_SLAVE_TYPE_RO  '0x10'$I2C_RO_SLAVE_ADDRESS > $I2C_NEW_DEV_PATH
    fi    
    if [ ! -f "$I2C_SLAVE_FILE_CONTROL" ]; then
        echo $I2C_RW_SLAVE_TYPE  '0x10'$I2C_RW_SLAVE_ADDRESS > $I2C_NEW_DEV_PATH_CONTROL
    fi
}

function populate_i2c_slave_telemetry_app_ver()
{
    # Set HMC telemetry SMBus telemetry app version
    echo -ne $I2C_DIRECT_APP_VERSION | dd of=$I2C_SLAVE_MEM_FILE bs=1 count=$I2C_DIRECT_APP_VERSION_SIZE seek=$I2C_DIRECT_APP_VERSION_OFFSET skip=0
}

function update_usb_status()
{
    usb_status=$(networkctl status usb0 | grep 'Online state:' | sed 's/^[^:]*[:]//')
    if [[ $usb_status == *"online"* ]];
    then
        data_array[5]=1
    else
        data_array[5]=0
    fi

    ip_string=$(networkctl status usb0 | grep -v 'Hardware' | grep ' Address: ' | sed 's/^[^:]*[:]//')
    # split using ' ' to get IP Address and then split agin with '.' for
    # each ip byte
    IFS=" " read -r -a ip_a <<< "$ip_string"
    IFS="." read -r -a ip_a <<< "${ip_a[0]}"
    data_array[6]=${ip_a[0]}
    data_array[7]=${ip_a[1]}
    data_array[8]=${ip_a[2]}
    data_array[9]=${ip_a[3]}    

    # fix for hmc booting with no static IP on usb0 interface
    # find the IP address of ubs0 interface, most recent IP would come at the top  
    ip_addr=$(networkctl status usb0 | grep -v 'Hardware' | grep ' Address: ' | sed 's/^[^:]*[:]//')
    # split with '.' delimiter 
    IFS="." read -r -a ip_a <<< "$ip_addr"
    if ([[ ${ip_a[0]} == *"169"* ]] && [[ ${ip_a[1]} == *"254"* ]]);
    then
        echo "Bad IP Configuration on usb0, found only link local IP"
        echo "Adding default static ip"
        ifconfig usb0 $HMC_IP up
    fi
}

function update_swversion()
{
    # Expected VERSION_ID core-XX.XX-rcx-xx-githash.xxxxxx.xxxxxx
    # Version ID string will be first split using '-'. 
    # Last element from the obtained array will again be split using '.' 
    # and first sub-string will be picked  
    version=$(grep 'VERSION_ID=' /etc/os-release)
    # if debug build 
    version=${version/'-dirty'}
    IFS="-" read -r -a v_a <<< "$version"
    IFS="." read -r -a g_hash_a <<< "${v_a[-1]}"
    data_array[0]=${g_hash_a[0]:1:1}
    data_array[1]=${g_hash_a[0]:2:2}
    data_array[2]=${g_hash_a[0]:4:2}
    data_array[3]=${g_hash_a[0]:6:2}
    data_array[4]=${g_hash_a[0]:8:2}
}

# HMC App status
function update_service_status()
{
  retval=$2
  service_status=$(systemctl status "$1" | grep 'Active: ')
  if [[ $service_status == *"running"* ]];
  then
        retval=$(($2 | $((1 << $3))))
  fi
  echo $retval
}

function update_pcie_link_status()
{
    FPGA_VEDNOR_ID="0x1172"
    FPGA_DEV_ID="0x0021"
    retval=$2
    path="/sys/bus/pci/devices/"
    num=$(ls $path |wc -l)

    #we epxect to have RC, bridge and FPGA
    if [[  $num -ne 3 ]];then
	echo $retval
	return;
    fi
    node=$(find $path -name "*:0[1-9]:00.*")
    if [[ -z "$node" ]];then
	echo $retval
	return;
    fi;
    vendor_id=$(cat $node/vendor)
    dev_id=$(cat $node/device)
    #check if it is FPGA
    if [[ $vendor_id == $FPGA_VEDNOR_ID ]] && [[ $dev_id == $FPGA_DEV_ID ]];then
        retval=$(($2 | $((1 << $3))))
    fi
    echo $retval
}

function update_rsyslog_status()
{
    retval=$1
    rsyslog_ip=$(busctl get-property xyz.openbmc_project.Syslog.Config /xyz/openbmc_project/logging/config/remote xyz.openbmc_project.Network.Client Address | awk '{ print $2 }')
    rsyslog_port=$(busctl get-property xyz.openbmc_project.Syslog.Config /xyz/openbmc_project/logging/config/remote xyz.openbmc_project.Network.Client Port | awk '{ print $2 }')

    if [[ $rsyslog_ip == "\"$BMC_IP\"" ]] && [[ $rsyslog_port == "6514" ]];then
        retval=$(($1 | $((1 << $2))))
    fi
    echo $retval
}

function update_service_status_all()
{
    # Bit 6 is set to true to indicate that we support remote logging on this level
    service_status=0x40
    service_status=$(update_service_status 'bmcweb' "$service_status" 0)
    service_status=$(update_service_status 'pldmd' "$service_status" 1)
    service_status=$(update_service_status 'nsmd' "$service_status" 2)
    service_status=$(update_service_status 'mctp-usb-ctrl' "$service_status" 3)
    service_status=$(update_service_status 'mctp-spi0-ctrl' "$service_status" 4)
    service_status=$(update_rsyslog_status "$service_status" 7)
    data_array[10]=$service_status

    # Additional Service Status in extended register 
    service_status=0x00
    service_status=$(update_service_status 'xyz.openbmc_project.Dump.Manager' "$service_status" 0)
    service_status=$(update_service_status 'mctp-usb-demux' "$service_status" 1)
    service_status=$(update_service_status 'mctp-spi0-demux' "$service_status" 2)
    data_array[14]=$service_status
}

function update_diagnostic_data()                                                          
{          
                
    declare -i fs_usage=0  
    if mountpoint /run/initramfs/rw &> /dev/null;
    then
        ## RWFS usage                                                                          
        rwfs=$(findmtd rwfs)                                                                   
        IFS=" " read -r -a u_a <<< $(df -h | grep /dev/mtdblock${rwfs#mtd})                    
        # 4th coloum has the used space in %       
        fs_usage=$(echo ${u_a[4]} | sed 's/.$//')    
        if [ "$((10#$fs_usage))" -ge 99 ];
        then
            rwfs_full=true
        else
            rwfs_full=false
        fi              
    fi 

    data_array[11]=$fs_usage                                 
                                                                                           
    ## Usbnet hardware bit status                                                          
    declare -i i=0                                                                         
    if [[ $(cat /sys/class/udc/*.udc/state) == *"configured"* ]];                          
    then                                                                                   
            i=$(($i | 1))                                                                  
    fi                                                                                     
    if [[ $(cat /sys/class/udc/*.udc/uevent | grep 'USB_UDC_DRIVER') == *"g_ether"* ]];    
    then                                                                                   
            i=$(($i | 2))                                                        
    fi                                                                                     
    if [[ $(cat /sys/class/net/usb0/operstate) == *"up"* ]];                               
    then                                                                                   
            i=$(($i | 4))                                                        
    fi                                                                                     
    data_array[12]=$i                                                                      
                                                                                           
}                                                                                                                                                      

function check_fs_recovery()
{
    ## init status as good
    declare -i i=0 
    data_array[13]=$i  
    # Check for previous recovery 
    recovery=$(fw_printenv | grep dataflashrecovery | sed 's/.*=//')
    if [ "$recovery" == "yes" ];
    then
        sleep 10 # wait for log service stratup 
        echo "Creating Redfish log for flash auto recovery"
        message_arg="HMC Flash,Data Corruption"
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

function update_hmc_uptime()
{
    # Get the system uptime in seconds
    uptime_seconds=$(cut -d '.' -f 1 /proc/uptime)

    # Convert uptime to hexadecimal bytes format
    uptime_hex=$(printf "%08x\n" "$uptime_seconds")

    UPTIME_IN_HEX=""
    for i in $(seq 0 2 6); do
        UPTIME_IN_HEX+='\x'${uptime_hex:i:2}
    done

    echo -ne $UPTIME_IN_HEX | dd of=$I2C_SLAVE_MEM_FILE bs=1 count=4 seek=16 skip=0 &> /dev/null
}

function eeprom_write()
{
    declare -a b
    declare -i i=0
    for i in $(seq 0 4); do b[$i]="${data_array[$i]}"; done
    ## Convert numbers to hex 
    re='^[0-9]+$'
    for i in $(seq 5 15); 
    do
        if [[ ${data_array[$i]} =~ $re ]]; then
            b[$i]=$(printf '%02x\n' "${data_array[$i]}")
        else
            b[$i]='00'
        fi
    done

    ## debug
    #echo "HMC boot progress:" "${data_array[@]}" ":" "${b[@]}"

    ## update the eeprom
    ## Set byte 0 to 0x00 to signal HMC BOOT COMPLETE byte
    echo -n -e \\x00\\x${b[0]}\\x${b[1]}\\x${b[2]}\\x${b[3]}\\x${b[4]}\\x${b[5]}\\x${b[6]}\\x${b[7]}\\x${b[8]}\\x${b[9]}\\x${b[10]}\\x${b[11]}\\x${b[12]}\\x${b[13]}\\x${b[14]}\\x${b[15]} \
        > $I2C_SLAVE_MEM_FILE
}

function reset_network_config_files()
{
    source_dir="/run/initramfs/rw/cow/etc/systemd/network/"
    ro_dir="/run/initramfs/ro/etc/systemd/network/"
    dest_dir="/etc/systemd/network/"

    # Check if destination directory exists, if not, create it
    mkdir -p "$dest_dir"

    # Loop through each file in the source directory
    for file in "$source_dir"*
    do
        [[ -e "$file" ]] || continue  # Skip files that not exist

        # Extract file name from the full path
        file_name=$(basename "$file")

        # Check if the same file exists in the read-only directory
        if [ -e "$ro_dir$file_name" ]; then
            # Copy the file contents from read-only directory to the destination directory
            cp "$ro_dir$file_name" "$dest_dir$file_name"
            echo "Copied $file_name"
        else
            echo "No corresponding file found for $file_name"
        fi
    done    
}

function monitor()
{
    ## ready the first byte from the mem file 
    f_opcode=$(hexdump -ve '1/1 "%02x"' $I2C_SLAVE_MEM_FILE_CONTROL -n 1)
    case $f_opcode in

    01)
        echo "Softreboot requested"
        create_reboot_event_log "Reboot triggered by external command over I2C"  
        reboot
        ;;
    02)
        echo "Network reset requested"
        systemctl stop systemd-networkd
        reset_network_config_files
        systemctl start systemd-networkd
        ;;
    03)
        echo "Request to turn remote logging ON"
        control_remote_logging "on"
        ;;
    04)
        echo "Request to turn remote logging OFF"
        control_remote_logging "off"
        ;;
    05)
        echo "Start of i2c dump server requested"
        systemctl start i2c-dump-server
        ;;       
    06)
        echo "Stop of i2c dump server requested"
        systemctl stop i2c-dump-server
        ;;   
    0e)
        echo "Dataflash erase requested"
        # Stop services which consume the log partition. They
        # will up again after reboot 
        systemctl stop xyz.openbmc_project.Logging.service
        systemctl stop xyz.openbmc_project.Dump.Manager.service

        if mountpoint /run/initramfs/rw &> /dev/null;
        then
            umount /dev/mtdblock6
        fi    
        if mountpoint /var/lib/logging &> /dev/null;
        then
            umount /dev/mtdblock7 
        fi
        flash_eraseall -q /dev/mtd6
        fw_setenv openbmclog dataflash-erase
        fw_setenv emmc_secure_erase_partition /var/emmc/user-logs
        # Need time here to ensure any background uboot-env (flash) update finishes before reboot 
        sleep 5 
        reboot        
        ;;          
    0f)
        echo "Factory reset requested"
        res=$(dbus-send --system --print-reply  --dest=xyz.openbmc_project.Software.BMC.Inventory /xyz/openbmc_project/software/bmc  xyz.openbmc_project.Common.FactoryReset.Reset)
        echo $res
        create_reboot_event_log "Factory Reset triggered by external command over I2C" 
        reboot        
        ;;    
    esac    

    # Reset the command byte
    echo -n -e \\xff > $I2C_SLAVE_MEM_FILE_CONTROL
}

function create_resource_event_log()
{
    message_arg="HMC $1,$2"
    busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} \
            ResourceEvent.1.0.ResourceErrorsDetected xyz.openbmc_project.Logging.Entry.Level.Critical 3 \
            REDFISH_MESSAGE_ID ResourceEvent.1.0.ResourceErrorsDetected \
            REDFISH_MESSAGE_ARGS "$message_arg" \
            xyz.openbmc_project.Logging.Entry.Resolution "If problem persists, try restarting HMC"    
}

function create_reboot_event_log()
{
    busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} \
            OpenBMC.0.4.BMCRebootReason xyz.openbmc_project.Logging.Entry.Level.Informational 2 \
            REDFISH_MESSAGE_ID OpenBMC.0.4.BMCRebootReason \
            REDFISH_MESSAGE_ARGS "$1"   
    # Time for log (flash) write to sync well. As this will follow an immediate reboot of the system
    sleep 2
}

declare -i event_delay_cnt=0
declare -i check_events=1 
declare -i loop_delay=5
declare -i fs_cur_usage=0                                                                                                          
declare -i fs_prv_usage=0                                                                                                          
enable_fs_usage_event=true   

function run_event_check()
{
    # events are checked every two minutes 
    if [ $event_delay_cnt -le 120 ]
    then
        event_delay_cnt=$event_delay_cnt+$1
    else
        event_delay_cnt=0
        ## HMC Ready - HMC_READY_CONTROL comes from /etc/default/platform_var.conf
        hmc_ready_pin=$(cat ${HMC_READY_CONTROL})
        if ([[ $hmc_ready_pin != *"1"* ]] && [[ $check_events == 1 ]]);
        then
            create_resource_event_log 'Ready' 'Service Unavailable'
            # USB connection
            usb_status=$(networkctl status usb0 | grep 'State:' | sed 's/^[^:]*[:]//')
            if [[ $usb_status != *"routable"* ]];
            then
                create_resource_event_log 'USB Connection' 'Service Unavailable'
            fi

            usb_status=$(networkctl status usb0 | grep 'Online state:' | sed 's/^[^:]*[:]//')
            if [[ $usb_status != *"online"* ]];
            then
                create_resource_event_log 'USB Network' 'Service Unavailable'
            fi

            ## BMC Web 
            service_status=$(systemctl status bmcweb | grep 'Active: ')
            if [[ $service_status == *"failed"* ]];
            then
                create_resource_event_log 'Redfish' 'Service Unavailable'
            fi   
            check_events=0           
        else
            # re-enable event logging 
            check_events=1
        fi  

        # log event when log partition usage increase above 90% 
        # the event is logged only once and gets enabled if usage falls below 80% 
        IFS=" " read -r -a u_a <<< $(df -h | grep $log_partition)                                                                             
        fs_cur_usage=$((10#$(echo ${u_a[4]} | sed 's/.$//')))                                                                                                                                                                                          
        if [ $fs_cur_usage -ge 90 ] && [ $fs_prv_usage -le 89 ] && [ $fs_prv_usage -ge 1 ] && [ $enable_fs_usage_event == "true" ];      
        then                    
            busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} \
                    ResourceEvent.1.0.ResourceStatusChangedWarning xyz.openbmc_project.Logging.Entry.Level.Informational 2 \
                    REDFISH_MESSAGE_ID ResourceEvent.1.0.ResourceWarningThresholdExceeded \
                    REDFISH_MESSAGE_ARGS "HMC Log Storage,90% Usage"                                                                                                                                                                                                                            
            enable_fs_usage_event=false                                                                                                
        fi                                                                                                                             
                                                                                                                                    
        if [ $fs_cur_usage -le 85 ];                                                                                                    
        then                                                                                                                           
            enable_fs_usage_event=true                                                                                                 
        fi                                                                                                                             
        fs_prv_usage=fs_cur_usage        

        update_hmc_uptime                                                                                                  
    fi 
}

declare -i fs_delay_cnt=0
function run_fs_health_check()
{
    if [ "$rwfs_full" == "true" ];
    then
        rwfs_full_counter=$((rwfs_full_counter+1))
    else
        rwfs_full_counter=0
    fi

    ## if rwfs partition is full 3 times in a row, we
    ## perform auto-recovery/factory-reset
    if [ $rwfs_full_counter -ge 3 ];
    then
        umount /dev/mtdblock6
        flash_eraseall -q /dev/mtd6
        message_arg="HMC Rwfs,Resource Exhaustion"
        busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} \
                ResourceEvent.1.0.ResourceErrorsCorrected xyz.openbmc_project.Logging.Entry.Level.Informational 2 \
                REDFISH_MESSAGE_ID ResourceEvent.1.0.ResourceErrorsCorrected \
                REDFISH_MESSAGE_ARGS "$message_arg"      
        sleep 5  
        create_reboot_event_log "Auto Recovery"  
        reboot
    fi 

    ## moutning log partition can take time in some cases so 
    ## helath check is delayed and done after 1.5 minutes
    if [ $fs_delay_cnt -le 90 ]
    then
        fs_delay_cnt=$fs_delay_cnt+$1
    else
        if [ "$fs_sanity" == "false" ]
        then
            fs_delay_cnt=0
            declare -i i=0 
            if ! mountpoint /run/initramfs/rw &> /dev/null;
            then
                echo "Mount missing at /run/initramfs/rw"
                # 0x80 for FS recovery, 0x01 for bad rwfs 
                i=$(($i | 129))
            fi    
            if ! mountpoint /var/lib/logging &> /dev/null;
            then
                echo "Mount missing at /var/lib/logging"
                # 0x80 for FS recovery, 0x02 for bad rwfs 
                i=$(($i | 130))
            fi
            data_array[13]=$i 
            eeprom_write

            fs_recovered=false
            if ! mountpoint /run/initramfs/rw &> /dev/null;
            then
                echo "Erasing /dev/mtd6 partition on detection of corruption"
                flash_eraseall -q /dev/mtd6
                fs_recovered=true
            fi    
            if ! mountpoint /var/lib/logging &> /dev/null;
            then
                log=$(findmtd log)
                if [[ -n "$log" ]]; then
                    echo "Erasing /dev/mtd7 partition on detection of corruption"
                    flash_eraseall -q /dev/mtd7
                fi
                # set uboot env for emmc erase
                echo "Erasing /var/emmc/user-logs partition on detection of corruption"
                fw_setenv emmc_secure_erase_partition /var/emmc/user-logs
                fs_recovered=true
            fi

            if [ "$fs_recovered" == "true" ]
            then
                # set uboot env and reboot 
                echo "Data flash recovery done, rebooting"
                fw_setenv dataflashrecovery yes  
                sleep 5    
                reboot   
            fi 
            fs_sanity=true        
        fi
    fi 
}

function control_remote_logging()
{
    # Call the remote logger config APIs to toggle remote logging
    if [[ $1 == "on" ]];
    then
        busctl set-property xyz.openbmc_project.Syslog.Config \
        /xyz/openbmc_project/logging/config/remote \
        xyz.openbmc_project.Logging.RsyslogClient Enabled b true

        busctl set-property xyz.openbmc_project.Syslog.Config \
        /xyz/openbmc_project/logging/config/remote \
        xyz.openbmc_project.Logging.RsyslogClient Severity s \
        "xyz.openbmc_project.Logging.RsyslogClient.SeverityType.All"

        busctl set-property xyz.openbmc_project.Syslog.Config \
        /xyz/openbmc_project/logging/config/remote \
        xyz.openbmc_project.Network.Client Port q 6514

        busctl set-property xyz.openbmc_project.Syslog.Config \
        /xyz/openbmc_project/logging/config/remote \
        xyz.openbmc_project.Network.Client Address s "$BMC_IP"
    else
        busctl set-property xyz.openbmc_project.Syslog.Config \
        /xyz/openbmc_project/logging/config/remote \
        xyz.openbmc_project.Logging.RsyslogClient Enabled b false

        busctl set-property xyz.openbmc_project.Syslog.Config \
        /xyz/openbmc_project/logging/config/remote \
        xyz.openbmc_project.Network.Client Port q 0

        busctl set-property xyz.openbmc_project.Syslog.Config \
        /xyz/openbmc_project/logging/config/remote \
        xyz.openbmc_project.Network.Client Address s ""
    fi
}

############################### main ##########################################
sleep 5
i2c_slave_create
update_swversion
check_fs_recovery
populate_i2c_slave_telemetry_app_ver

while true; do
    update_usb_status
    update_service_status_all
    update_diagnostic_data
    eeprom_write
    monitor
    run_fs_health_check $loop_delay
    run_event_check $loop_delay
    sleep $loop_delay
done



