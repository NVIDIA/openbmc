#!/bin/sh

# the cpld version is fetched over i2c command
# the cpld will return the version in the format of "0x04 0x00 0x01 0x02 0x00"
# the version needs to be reported as third_hex_from_right + "v" + second_hex_from_right + first_hex_from_right
# this way the reported version will match what pldm bundle has

string=''

string=''
i2c_read() {
    if [ "$3" == "0x9e" ]; then
        string="CPLDSerialNumber"
    elif [ "$3" == "0xab" ]; then
        string="CPLDPartNumber"
    elif [ "$3" == "0x99" ] && [ "$1" == "255" ]; then
        string="Intel"
    elif [ "$3" == "0x9a" ] && [ "$1" == "255" ]; then
        string="MAX10"
    elif [ "$3" == "0x2d" ] && [ "$1" == "255" ]; then
        tmp="$(i2ctransfer -y 8 w2@0x39 0x00 0x00 r5)"
        hex_values=($(echo $tmp | sed 's/0x//g'))
        third_hex=${hex_values[-3]}
        second_hex=${hex_values[-2]}
        first_hex=${hex_values[-1]}
        third_dec=$(printf "%d" 0x$third_hex)
        second_dec=$(printf "%d" 0x$second_hex)
        first_dec=$(printf "%d" 0x$first_hex)
        string="${third_dec}.${second_dec}${first_dec}"
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
