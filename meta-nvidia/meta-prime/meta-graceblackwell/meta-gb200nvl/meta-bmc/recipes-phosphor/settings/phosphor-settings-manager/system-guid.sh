#!/bin/bash

# Get platform variables
source /etc/default/platform_var.conf

fruDeviceCommand="dbus-send --system --print-reply \
                  --dest=xyz.openbmc_project.ObjectMapper \
                  /xyz/openbmc_project/object_mapper \
                  xyz.openbmc_project.ObjectMapper.GetSubTreePaths \
                  string:'/xyz/openbmc_project/FruDevice/' \
                  int32:0 array:string:'xyz.openbmc_project.FruDevice' | grep -o 'string \".*\"' | cut -d' ' -f2 | sed 's/\"//g'"

function getDbusProperty()
{
    objpath=$1
    property=$2
    value=$(busctl get-property xyz.openbmc_project.FruDevice \
                                ${objpath} \
                                xyz.openbmc_project.FruDevice \
                                ${property} 2>/dev/null)
    if [ $? -eq 0 ];
    then
        echo ${value}
    fi
    echo ""
}

function getMacAddress()
{
    objpath=$1
    boardInfo="BOARD_INFO_AM1 BOARD_INFO_AM2 BOARD_INFO_AM3"
    for boardAm in ${boardInfo}; do
        value=$(getDbusProperty "${objpath}" "${boardAm}")
        if [ ! -z "${value}" ];
        then
            foundMac=$(echo ${value} | grep -i "MAC:\|MAC1:")
            if [ ! -z "${foundMac}" ];
            then
                echo ${foundMac}
            fi
        fi
    done
    echo ""
}

function pingFruDevice()
{
    ret="1"
    counter=0
    while [ ${counter} -lt 60 ];
    do
        output=$(eval ${fruDeviceCommand})
        if [ ! -z "${output}" ];
        then
            ret="0"
            break
        fi
        ((counter++))
        sleep 1
    done
    echo $ret
}

uid="/etc/machine-id"
service="xyz.openbmc_project.Settings"
objPath="/xyz/openbmc_project/Common/UUID"
uuidInterface="xyz.openbmc_project.Common.UUID"
uuidProperty="UUID"

# test if FruDevice is ready
ret=$(pingFruDevice)
if [ "$ret" == "0" ];
then
    # if FruDevice has data, wait 3s to make sure all frus are ready
    sleep 3
else
    echo "Failed to find a fru to generate GUID from, persisting current machine id"

    line=`awk '{ print }' $uid`
    echo $line
    uuid="${line:0:8}-${line:8:4}-${line:12:4}-${line:16:4}-${line:20:12}"
    busctl set-property $service $objPath $uuidInterface $uuidProperty s $uuid

    exit 1
fi

# seed sha1 input with "NVIDIA" namespace to differentiate from another vendor
# if they happened to use the same hash inputs and has the same product/serial
# num combo
sha1_input="NVIDIA"

while read -r line; do

    # If the product is a BMC board we will add the Part Number, MAC address, and Serial Number
    # to the hash input. The MAC is included for this case to differentiate early systems that
    # may have been programmed with a common serial number such as "1234567890123".
    # The following is a list of BMC boards that will be added, if found, to the hash input
    #
    if [ $(echo $line | grep -i "${bmc_board}") ];
    then
        bmc_part_num=$(getDbusProperty "${line}" "BOARD_PART_NUMBER" | awk -F'"' '{print $2}')
        echo "adding bmc board part num to sha input = ${bmc_part_num}"
        sha1_input="${sha1_input} ${bmc_part_num}"

        bmc_mac_num=$(getMacAddress "${line}" | awk -F'"' '{print $2}' | sed 's/ //')
        bmc_mac_num="${bmc_mac_num#*:}"
        echo "adding bmc board mac to sha input = ${bmc_mac_num}"
        sha1_input="${sha1_input} ${bmc_mac_num}"

        bmc_serial_num=$(getDbusProperty "${line}" "BOARD_SERIAL_NUMBER" | awk -F'"' '{print $2}')
        echo "adding bmc board serial num to sha input = ${bmc_serial_num}"
        sha1_input="${sha1_input} ${bmc_serial_num}"
    fi

    # We will concatenate the baseboard's part number and serial number with this. This is
    # done to meet the IPMI spec requirement that the GUID change if the BMC module is moved
    # to another system.
    # The following is a list of baseboards that will be added, if found, to the hash input
    #   P4486
    #
    # Note: if we can converge on a baseboard with the chassis type set to rack mount or main
    #       server, we can simplify this by just having it use FRU ID 0 instead of needing
    #       to rely on a hard coded list of products
    if [ $(echo $line | grep -i "${board_list}") ];
    then
        board_part_num=$(getDbusProperty "${line}" "BOARD_PART_NUMBER" | awk -F'"' '{print $2}')
        echo "adding board part num to sha input = ${board_part_num}"
        sha1_input="${sha1_input} ${board_part_num}"

        board_serial_num=$(getDbusProperty "${line}" "BOARD_SERIAL_NUMBER" | awk -F'"' '{print $2}')
         echo "adding board serial num to sha input = ${board_serial_num}"
        sha1_input="${sha1_input} ${board_serial_num}"
    fi
done <<< $(eval ${fruDeviceCommand})

echo "sha1 input: ${sha1_input}"

# compute sha1 of input
sha1_r=$(echo ${sha1_input} | sha1sum)
echo "sha1 result: ${sha1_r}"

# create uuid from sha1 result - https://www.ietf.org/rfc/rfc4122.txt
# set 2 msb of this 4 bits to the reserved bits 10 per section 4.1.1
clk_seq_hi_res=$(printf "%x" $(($(echo 0x${sha1_r:16:1})&0x3|0x8)))
# 5 in 4 msb of byte 13 = 0101 which is name based version using sha-1 hashing per section 4.1.3
sha1_uuid="${sha1_r:0:8}-${sha1_r:8:4}-5${sha1_r:13:3}-${clk_seq_hi_res}${sha1_r:17:3}-${sha1_r:20:12}"
echo "sha1 uuid: ${sha1_uuid}"

busctl set-property $service $objPath $uuidInterface $uuidProperty s $sha1_uuid

# Update machine-id in case other services are relying on it. This will help keep us consistent across interfaces
# sha1_uuid_unformatted="${sha1_r:0:8}${sha1_r:8:4}5${sha1_r:13:3}${clk_seq_hi_res}${sha1_r:17:3}${sha1_r:20:12}"
# echo ${sha1_uuid_unformatted} > /tmp/new-machine-id
# mv /tmp/new-machine-id /etc/machine-id
