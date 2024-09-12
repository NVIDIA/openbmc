#!/bin/bash
OPCODE="$1"
ARGS=${2:-"0x00"}
TIMEOUT=${3:-30} # timeout in seconds

SCRIPT_DIR=$(dirname "$0")

source "$SCRIPT_DIR/_utils.sh"

error() {
    msg="$1"
    exit_code=${2:-1}

    echo "$msg"
    exit $exit_code
}

if [[ -z "$OPCODE" ]]; then
    error "Opcode not given. Please provide opcode."
fi

args_size=$(echo "$ARGS" | wc -w)
if [[ $args_size -gt 16 ]]; then
    error "More than 16 bytes given as an argument. Max is 16."
fi

# prepare all arguments
write_size=$((2+args_size))
if ! i2ctransfer -y 1 w${write_size}@0x45 0x01 $OPCODE $ARGS; then
    error "Failed to execute i2ctransfer command: \"i2ctransfer -y 1 w${write_size}@0x45 0x01 $OPCODE $ARGS\""
fi

# Start a command
if ! i2cset -y 1 0x45 18 1; then
    error "Failed to execute i2cset command: \"i2cset -y 1 0x45 18 1\""
fi

timeout=5 # timeout in seconds
start_time=$(get_time)
while true; do
    if [[ $(($(get_time) - start_time)) -ge $timeout ]]; then
        error "Waitng for clearing request bit by HMC more than $timeout seconds."
    fi
    request_bit=$(i2cget -y 1 0x45 18)
    if [[ "$request_bit" == "0x00" ]]; then
        break
    fi
    sleep 0.1
done

timeout=$TIMEOUT
start_time=$(get_time)
while true; do
    if [[ $(($(get_time) - start_time)) -ge $timeout ]]; then
        error "Waitng for for the command to complete more than $timeout seconds."
    fi
    execution_status=$(i2cget -y 1 0x45 19)
    if [[ "$execution_status" == "0x00" ]]; then
        break
    fi
    sleep 0.1
done

if ! data=$(i2ctransfer -y 1 w1@0x45 20 r17); then
    error "Failed to get status and response. Cmd: \"i2ctransfer -y 1 w1@0x45 20 r17\""
fi

status_code_hex=$(echo "$data" | cut -d ' ' -f 1)
if [[ "$status_code_hex" != "0x00" ]]; then
    status_code=$(hex_to_dec "$status_code_hex")
    error "Command status code != 0." $status_code
fi

echo "$data" | cut -d ' ' -f 2-
