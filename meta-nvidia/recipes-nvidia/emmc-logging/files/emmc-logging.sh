#!/bin/sh

LOGGING_DIR="/var/lib/logging"
SPIFLASH="/dev/mtdblock7"
LOGGING_DIR_TEMP="/tmp/logging"

remove_dump() {
    local src_dir=$1
    local dest_dir=$2

    # Iterate over all files and directories in the source directory
    find "$src_dir" | while read -r src_item; do
        # Calculate the destination path
        relative_path="${src_item#$src_dir/}"
        dest_item="$dest_dir/$relative_path"
        dest_parent_dir=$(dirname "$dest_item")
        if [ -d "$dest_parent_dir" ]; then
            #removing the "$dest_item" if it is tar as we found a copy in spi flash will keep spi flash one
            rm -f "$dest_parent_dir"/obmcdump*  
            #need to remove only the files as removing whole directory will remove the upper layer folders also, like bmc and system.
        fi
    done
}

cleanUp_Journal_folder() {
    local mount_point="$1"
    # Read the machine ID
    machine_id=$(cat /etc/machine-id)
    # Define the directory containing the logs
    log_dir="$mount_point"/journal-logs
    # Check if the log directory exists
    if [ -d "$log_dir" ]; then
        # Iterate over all directories in the log directory
        for dir in "$log_dir"/*;
            do
            # Check if it's a directory and not the one with the machine ID
            if [ -d "$dir" ] && [ "$(basename "$dir")" != "$machine_id" ]; then
                # Delete the directory
                rm -rf "$dir"
                echo "Deleted: $dir"
            fi
            done
    else
        echo "Log directory does not exist: $log_dir"
    fi
}

create_default_mount() {
    # If /var/emmc doesn't exist, mount /var/lib/logging to /dev/mtdblock7
    if [ ! -d "$LOGGING_DIR" ]; then
        mkdir -p "$LOGGING_DIR"
    fi

    # Mount /var/lib/logging to /dev/mtdblock7 with jffs2 filesystem
    mount -t jffs2 -o rw,relatime,sync "$SPIFLASH" "$LOGGING_DIR"

    echo "Mounted /var/lib/logging to $SPIFLASH"
    return 1
}

create_logging_emmc_mount() {
    local EMMC_DIR="$1"
    if mountpoint "$EMMC_DIR"; then
        mkdir -p "$EMMC_DIR"/logging  #creating logging directory for the emmc 
        mkdir -p "$LOGGING_DIR_TEMP"   #creating temp directory for the spi flash data
        #mount it to spi flash partition
        if timeout 10 mount -t jffs2 -o rw,relatime,sync "$SPIFLASH" "$LOGGING_DIR_TEMP"; then
            if [ "$(ls -A "$LOGGING_DIR_TEMP")" ]; then
                remove_dump "$LOGGING_DIR_TEMP"/dumps "$EMMC_DIR"/logging/dumps   #remove the duplicate folder contents from emmc
                cp -r "$LOGGING_DIR_TEMP"/* "$EMMC_DIR"/logging #copy the contents to emmc
                rm -rf "$LOGGING_DIR_TEMP"/*
                echo "Data copied from spi flash logging to /var/emmc/user-logs/logging/ and spi flash cleaned up."
            else
                echo "no data present for copying"
            fi
            umount "$LOGGING_DIR_TEMP" #unmounting temp for logging 
            rm -rf "$LOGGING_DIR_TEMP" # deleting temp for logging we can't do before as it will show Device or resource busy due to mounting
        else
        # Check the return code to determine the type of failure
        ret=$?
        if [ $ret -eq 124 ]; then
            echo "Mount command timed out"
        else
            echo "Mount command failed with return code $ret"
        fi
    fi

        # creating logging dir for the emmc
        mkdir -p "$LOGGING_DIR" 
        #create a mount poitn for the /var/lib/logging to emmc folder
        mount --bind "$EMMC_DIR"/logging "$LOGGING_DIR"
        return 0
    else
        create_default_mount
        echo "Error: Emmc Mount point not found. Falling to $SPIFLASH."
    fi
}

create_journal_link() {
   local mount_point="$1"
   local required_fs="$2"
   # Check if the mount point exists
   if [ -d "$mount_point" ]; then
       # Check if the filesystem type is matches
       local filesystem_type=$(df -T "$mount_point" | awk 'NR==2 {print $2}')
       if [ "$filesystem_type" == "$required_fs" ]; then
           # Mount point exists and has ext4 filesystem that is what for the emmc is, create a soft link
           mkdir -p "$mount_point"/journal-logs
           cleanUp_Journal_folder "$mount_point"
           ln -s -T "$mount_point"/journal-logs /var/log/journal
           journalctl --flush

           return 0
       else
           # Mount point exists but doesn't have required filesystem, return error code 2
           return 2
       fi
   else
       # Mount point does not exist, return error code 1
       return 1
   fi
}

main() {
    # Check if all required arguments are provided
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 <mount_point> <required_fs>"
        create_default_mount
        echo "Error: Emmc Mount point not found. Falling to $SPIFLASH."
        exit 1
    fi

    local mount_point="$1"
    local required_fs="$2"
    local sleep_cnt=0

    while true; do
        sleep 2
        sleep_cnt=$((sleep_cnt + 1))
        status=$(systemctl is-active nvidia-emmc-partition.service)

        # Check if the status is "active"
        if [ "$status" == "active" ]; then
            echo "The service is active."
            create_logging_emmc_mount "$mount_point"
            result=$?
            if [ "$result" -eq 0 ]; then
                echo "Mount point for /var/lib/logging is created successfully."
            elif [ "$result" -eq 1 ]; then
                echo "Error: Emmc Mount point not found. Falling to $SPIFLASH."
            fi
            break
        fi

        # Break the loop if the service is failed or timeout happens
        if [ "$status" == "failed" ] || [ "$sleep_cnt" -ge 25 ]; then
            create_default_mount
            echo "Error: Emmc Mount point failed. Falling to $SPIFLASH."
            break
        fi
    done

    create_journal_link "$mount_point" "$required_fs"
    result=$?
    if [ "$result" -eq 0 ]; then
        echo "Soft link is created successfully."
        exit 0
    elif [ "$result" -eq 1 ]; then
        echo "Error: Mount point not found."
        exit 1
    elif [ "$result" -eq 2 ]; then
        echo "Error: Mount point does not have '$required_fs' filesystem."
        exit 1
    fi
}

# Call the main function with all script arguments
main "$@"
