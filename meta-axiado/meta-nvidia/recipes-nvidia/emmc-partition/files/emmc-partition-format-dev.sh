#!/bin/sh

# Create dict for dev build so we don't have to touch emmc partitions
mount_map=$(cat /usr/share/emmc/emmc-mount.conf)
while IFS= read -r l
do
    eval "arr=($l)"
    mount_point=${arr[1]}
    mkdir -p $mount_point
done <<< "$mount_map"
