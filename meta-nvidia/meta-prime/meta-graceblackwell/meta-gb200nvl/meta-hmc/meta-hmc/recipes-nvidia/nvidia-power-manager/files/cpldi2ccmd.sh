#!/bin/sh

# the cpld version is fetched over i2c command
# the cpld will return the version in the format of "0x04 0x00 0x01 0x02 0x00"
# the version needs to be reported as third_hex_from_right + "v" + second_hex_from_right + first_hex_from_right
# this way the reported version will match what pldm bundle has

string=''

string=''
i2c_read() {
    # SerialNumber
    if [ "$3" == "0x9e" ]; then
        string="NA"
    # PartNumber
    elif [ "$3" == "0xad" ]; then
        string="115-3953-000"
    # Manufacturer
    elif [ "$3" == "0x99" ] && [ "$1" == "255" ]; then
        string="Intel"
    # Model
    elif [ "$3" == "0x9a" ] && [ "$1" == "255" ]; then
        string="MAX10 10M08"
    # Version
    elif [ "$3" == "0x2d" ] && [ "$1" == "255" ]; then
        tmp="$(i2ctransfer -y 8 w2@0x39 0x00 0x00 r5)"
        hex_values=($(echo $tmp | sed 's/0x//g'))
        third_hex=$(echo ${hex_values[-3]} | sed 's/^0//g')
        second_hex=$(echo ${hex_values[-2]} | sed 's/^0//g')
        first_hex=$(echo ${hex_values[-1]} | sed 's/^0//g')
        string="${third_hex^^}.${second_hex^^}${first_hex^^}"
    fi
}

if [ $# -eq 0 ]; then
    echo 'No device is given' >&2
    exit 1
fi

input=$(echo $1 | tr "-" " ")
arr=(${input// / });
i2c_read ${arr[1]} ${arr[2]} ${arr[3]} ${arr[4]}
echo ${string}
