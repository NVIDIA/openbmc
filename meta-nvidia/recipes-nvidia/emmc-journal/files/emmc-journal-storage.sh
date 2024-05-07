#!/bin/sh

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
           ln -s "$mount_point"/journal-logs /var/log/journal
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

# Check if all required arguments are provided
if [ "$#" -ne 2 ]; then
   echo "Usage: $0 <mount_point> <required_fs>"
   exit 1
fi

mount_point="$1"
required_fs="$2"

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
# Mount point is not available or doesn't have required filesystem
