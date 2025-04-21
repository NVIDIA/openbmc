#!/bin/bash

# 1 - HMC dump
# 2 - FPGA Reg Table
# 3 - ERoT
DUMP_TYPE=${1:-1}
DUMP_NAME=${2:-"dump.tar.xz"}

SCRIPT_DIR=$(dirname "$0")

source "$SCRIPT_DIR/_utils.sh"

error() {
    echo "ERROR: $1"
    # Stop i2c dump server on HMC
    i2ctransfer -y 1 w2@0x45 0x00 0x06
    exit 1
}

dump_type_is_valid=false
for expected_type in 1 2 3; do
    if [[ "$expected_type" -eq "$DUMP_TYPE" ]]; then
        dump_type_is_valid=true
        break
    fi
done

if [[ "$dump_type_is_valid" == false ]]; then
    error "Unknow dump type: $DUMP_TYPE"
fi


if [[ "$DUMP_TYPE" -eq 1 ]]; then
    dump_type=1 # bmc
    dump_sub_type=1
else
    dump_type=2 # system
    dump_sub_type=$((DUMP_TYPE-1))
fi

echo "$(date) Turn on i2c dump server on HMC..."
if ! i2ctransfer -y 1 w2@0x45 0x00 0x05; then
    error "Cannot start i2c dump server on HMC."
fi
sleep 3 # Wait for the script to launch
echo ""

echo "$(date) Init dump creation..."
output=$($SCRIPT_DIR/execute_command.sh 1 "$dump_type $dump_sub_type")
exit_code=$?
if [[ $exit_code -eq 2 ]]; then
    error "Another dump creation already in progress. Try again in couple of minutes."
elif [[ $exit_code -ne 0 ]]; then
    error "$output"
fi

entry_id_hex=$(echo "$output" | cut -d ' ' -f 1-2)
entry_id=$(hex_to_dec "$entry_id_hex")

echo "$(date) Dump creation initiated. Entry id: $entry_id ($entry_id_hex)"

timeout=$((30*60)) # 30min timeout for creating a dump
start_time=$(get_time)
while true; do
    if [[ $(($(get_time) - start_time)) -ge $timeout ]]; then
        error "Waitng for for the dump generation more than $((timeout/60)) min."
    fi
    if ! output=$($SCRIPT_DIR/execute_command.sh 2 "$dump_type $entry_id_hex"); then
        echo "ERROR: $output"
    else
        status=$(echo "$output" | cut -d ' ' -f 1)
        progress=$(hex_to_dec "$(echo "$output" | cut -d ' ' -f 2)" )
        if [[ "$status" == "0x00" ]]; then
            echo -ne "\r$(date) Dump($entry_id) creation is in progress.. Percentage: ${progress}%"
        elif [[ "$status" == "0x01" ]]; then
            dump_size_hex=$(echo "$output" | cut -d ' ' -f 3-6)
            dump_size=$(hex_to_dec "$dump_size_hex")
            break
        fi
    fi
    sleep 5
done
echo ""
echo "$(date) Dump($entry_id) creation completed. Dump size: $dump_size. Creation time: $(($(get_time) - start_time)) seconds"

if [[ $dump_size -eq 0 ]]; then
    error "Generated dump is zero bytes."
fi

left_bytes_to_copy=$dump_size

if [[ -f $DUMP_NAME ]]; then
    rm "$DUMP_NAME"
fi
touch "$DUMP_NAME"


block_number=0
start_time=$(get_time)
while [[ $left_bytes_to_copy -gt 0 ]]; do

    echo "$(date) Request for block number $block_number."
    block_number_hex=$(printf '%04x\n' $block_number)
    if ! output=$($SCRIPT_DIR/execute_command.sh 3 "$dump_type $entry_id_hex 0x${block_number_hex:0:2} 0x${block_number_hex:2:2}"); then
        error "Request file block data failed. Msg: $output"
    fi
    
    # Get block_size
    if ! output=$(i2ctransfer -y 2 w2@0x4f 0x05 0x00 r4 2>&1); then
        error "Failed to read block size. Cmd: i2ctransfer -y 2 w2@0x4f 0x05 0x00 r4. Err Msg: $output"
    fi
    block_size=$(hex_to_dec "$output")
    echo "Block $block_number size: $block_size. left_bytes_to_copy: $left_bytes_to_copy"

    # read a data and save it to a file
    if ! output=$(i2ctransfer -y 2 w2@0x4f 0x05 0x04 r$block_size); then
        error "Failed to read block data. Cmd: i2ctransfer -y 2 w2@0x4f 0x05 0x04 r$block_size. Err Msg: $output"
    fi
    echo "$output" | awk -f $SCRIPT_DIR/hex-to-bin.awk  >> $DUMP_NAME

    left_bytes_to_copy=$((left_bytes_to_copy-block_size))
    block_number=$((block_number+1))

done

echo "$(date) Dump($DUMP_NAME) download completed. Dump size: $dump_size. Download time: $(($(get_time) - start_time)) seconds"

echo "$(date) Turn off i2c dump server on HMC..."
if ! i2ctransfer -y 1 w2@0x45 0x00 0x06; then
    error "Cannot stop i2c dump server on HMC."
fi
