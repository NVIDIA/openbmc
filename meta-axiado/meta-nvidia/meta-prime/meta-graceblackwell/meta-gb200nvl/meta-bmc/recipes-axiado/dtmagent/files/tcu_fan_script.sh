#!/bin/bash
# tcu_fan_script.sh
#   ./tcu_fan_script.sh read
#   ./tcu_fan_script.sh write <DUTY_VALUE>


read_fans() {
    declare -A FAN_BUS FAN_DEV FAN_REG_H FAN_REG_L
    FAN_BUS=( [0]=10 [1]=10 [2]=10 [3]=10 )
    FAN_DEV=( [0]=0x20 [1]=0x23 [2]=0x2C [3]=0x2F )

    FAN_REG_A_H=( [0]=0x20 [1]=0x18 [2]=0x20 [3]=0x18 )
    FAN_REG_A_L=( [0]=0x21 [1]=0x19 [2]=0x21 [3]=0x19 )

    FAN_REG_B_H=( [0]=0x22 [1]=0x1A [2]=0x22 [3]=0x1A )
    FAN_REG_B_L=( [0]=0x23 [1]=0x1B [2]=0x23 [3]=0x1B )

    read_i2c_retry() {
        local bus=$1
        local dev=$2
        local reg=$3
        local val
        while true; do
            val=$(i2cget -f -y -a "$bus" "$dev" "$reg" 2>/dev/null)
            if [ $? -eq 0 ]; then
                echo "$val"
                return
            else
                sleep 0.1
            fi
        done
    }

    for i in {0..3}; do
        local bus=${FAN_BUS[$i]}
        local dev=${FAN_DEV[$i]}
        local regAH=${FAN_REG_A_H[$i]}
        local regAL=${FAN_REG_A_L[$i]}
        local regBH=${FAN_REG_B_H[$i]}
        local regBL=${FAN_REG_B_L[$i]}

        local highA=$(read_i2c_retry $bus $dev $regAH)
        local lowA=$(read_i2c_retry $bus $dev $regAL)
        local highB=$(read_i2c_retry $bus $dev $regBH)
        local lowB=$(read_i2c_retry $bus $dev $regBL)

        local tach_count_A=$(( (highA << 3) | (lowA >> 5) ))
        local tach_count_B=$(( (highB << 3) | (lowB >> 5) ))

        local rpm_A=$(( tach_count_A == 0 ? 0 : 983040 / tach_count_A ))
        local rpm_B=$(( tach_count_B == 0 ? 0 : 983040 / tach_count_B ))

        echo "RPM${i}_A=$rpm_A | RPM${i}_B=$rpm_B"
    done
}

write_fans() {
    local DUTY="$1"
    if [ -z "$DUTY" ]; then
        echo "Usage: $0 write <DUTY(1~100)>"
        exit 1
    fi
    if ! [[ "$DUTY" =~ ^[0-9]+$ ]] || [ "$DUTY" -lt 1 ] || [ "$DUTY" -gt 100 ]; then
        echo "Error: duty must be 1~100"
        exit 1
    fi

    local DUTY_VAL=$(( DUTY * 255 / 100 ))
    local DUTY_HEX=$(printf "0x%02X" $DUTY_VAL)

    declare -A FAN_BUS FAN_DEV FAN_REG
    FAN_BUS=( [0]=10 [1]=10 [2]=10 [3]=10 [4]=10 [5]=10 [6]=10 [7]=10 [8]=10 [9]=10 [10]=10 [11]=10 [12]=10 [13]=10 [14]=10 [15]=10 [16]=10 [17]=10 [18]=10 [19]=10 [20]=10 [21]=10 [22]=10 [23]=10 )
    FAN_DEV=( [0]=0x20 [1]=0x20 [2]=0x20 [3]=0x20 [4]=0x20 [5]=0x20 [6]=0x23 [7]=0x23 [8]=0x23 [9]=0x23 [10]=0x23 [11]=0x23 [12]=0x2C [13]=0x2C [14]=0x2C [15]=0x2C [16]=0x2C [17]=0x2C [18]=0x2F [19]=0x2F [20]=0x2F [21]=0x2F [22]=0x2F [23]=0x2F )
    FAN_REG=( [0]=0x40 [1]=0x42 [2]=0x44 [3]=0x46 [4]=0x48 [5]=0x4A [6]=0x40 [7]=0x42 [8]=0x44 [9]=0x46 [10]=0x48 [11]=0x4A [12]=0x40 [13]=0x42 [14]=0x44 [15]=0x46 [16]=0x48 [17]=0x4A [18]=0x40 [19]=0x42 [20]=0x44 [21]=0x46 [22]=0x48 [23]=0x4A )

    for i in {0..23}; do
        i2cset -f -y -a "${FAN_BUS[$i]}" "${FAN_DEV[$i]}" "${FAN_REG[$i]}" "$DUTY_HEX" || \
        echo "Failed to set Fan $i (bus=${FAN_BUS[$i]} dev=${FAN_DEV[$i]} reg=${FAN_REG[$i]})"
    done
    echo "All fans PWM duty set to $DUTY%."
}

# --- Main ---
case "$1" in
    read)
        read_fans
        ;;
    write)
        write_fans "$2"
        ;;
    *)
        echo "Usage:"
        echo "  $0 read"
        echo "  $0 write <DUTY(1~100)>"
        exit 1
        ;;
esac
