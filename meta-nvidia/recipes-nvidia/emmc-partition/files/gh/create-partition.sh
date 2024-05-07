#!/bin/sh
#Emmc Partitioning for GH

device1=$1
if [ -b "/dev/$device1" ]
then 
echo "EMMC- Starting disk partition..!!"

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk "/dev/$device1"
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
  +64M # 1MB u-boot partition
  p # print the in-memory partition table

  n # new partition
  p # primary partition
  2 # partition number 2
    # default - start at beginning of disk
  +3G # 2GB Firmware partition
  p # print the in-memory partition table

  n # new partition
  p # primary partition
  3 # partition number 4
    # default - start at beginning of disk
  +1G # 1GB user log partition
  p # print the in-memory partition table

  n # new partition
  e # extended partition
  4 # partition number 3
    # default - start at beginning of disk
    # default - end of disk
  p # print the in-memory partition table

  n # new partition
  l " logical partition
  5 # partition number 5
    # default - start at beginning of disk
  +2G # 3GB FDR partition
  p # print the in-memory partition table

  n # new partition
  l # logical partition
  6 # partition number 6
    # default - start at beginning of disk
  +1M # 768M Embedded Diags
  p # print the in-memory partition table
  w # write the partition table
EOF
fi