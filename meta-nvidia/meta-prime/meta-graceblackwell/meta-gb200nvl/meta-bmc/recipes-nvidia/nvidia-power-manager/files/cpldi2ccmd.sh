#!/bin/sh

string=''

string=''
i2c_read() {
    # SerialNumber
    if [ "$3" == "0x9e" ]; then
        # Get from TraceID register
        tmp="$(i2ctransfer -y -f $1 w4@$2 0x19 0x0 0x0 0x0 r8)"
        string=$(echo $tmp | sed 's/ 0x//g')
    # PartNumber
    elif [ "$3" == "0xad" ]; then
        string="999-0099-000"
    # Manufacturer
    elif [ "$3" == "0x99" ]; then
        string="Lattice"
    # Model
    elif [ "$3" == "0x9a" ]; then
        string="MachXO2-4000/MachXO2-2000U"
    # Version
    elif [ "$3" == "0x2d" ]; then
        string="$(i2ctransfer -y -f $1 w3@$2 0xc0 0x0 0x0 r4)"
    fi
}


if [ $# -eq 0 ]; then
    echo 'No device is given' >&2
    exit 1
fi

input=$(echo $1 | tr "-" " ")
arr=(${input// / });
i2c_read ${arr[1]} ${arr[2]} ${arr[3]} ${arr[4]}
echo $string
