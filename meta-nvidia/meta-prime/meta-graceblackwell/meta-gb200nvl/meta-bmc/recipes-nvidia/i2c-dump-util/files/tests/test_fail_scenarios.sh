#!/bin/bash

# Test covers test ids:
# I2C_DUMP_3 - I2C Dump creation when previous I2C Dump creation is in progress
# I2C_DUMP_3 - RF Dump creation when I2C Dump creation is in progress
# I2C_DUMP_4 - I2C Dump download without dump creation
# I2C_DUMP_4 - Request file block data with a wrong block number

TOOL_DIR=$(dirname $(dirname $0))
if [[ $TOOL_DIR == "." ]]; then
    TOOL_DIR=".."
fi
HMC_IP=172.31.13.251

source $TOOL_DIR/_utils.sh

DUMP_TYPE=1
DUMP_SUB_TYPE=1

error() {
    msg="$1"
    echo "ERROR: $msg"
    echo ""
    echo "Test result: FAILED"

    # Stop i2c dump server on HMC
    i2ctransfer -y 1 w2@0x45 0x00 0x06

    exit 1
}

echo "$(date) Turn on i2c dump server on HMC..."
if ! i2ctransfer -y 1 w2@0x45 0x00 0x05; then
    error "Cannot start i2c dump server on HMC."
fi
sleep 3 # Wait for the script to launch
echo ""

echo "$(date) Init dump creation..."
output=$($TOOL_DIR/execute_command.sh 1 "$DUMP_TYPE $DUMP_SUB_TYPE")
exit_code=$? 
if [[ $exit_code -ne 0 ]]; then
    error "Can't initiate dump creation."
fi
entry_id_hex=$(echo "$output" | cut -d ' ' -f 1-2)
entry_id=$(hex_to_dec "$entry_id_hex")
echo ""


echo "$(date) I2C_DUMP_3 - I2C Dump creation when previous I2C Dump creation is in progress."
output=$($TOOL_DIR/execute_command.sh 1 "$DUMP_TYPE $DUMP_SUB_TYPE")
exit_code=$? 
if [[ $exit_code -eq 2 ]]; then
    echo "Expected exit code 2 return."
    echo "TC result: PASSED"
else
    error "When previous dump creation is in progress, expected exit code is 2, not $exit_code. Cmd output: $output"
fi
echo ""

echo "$(date) I2C_DUMP_3 - RF Dump creation when I2C Dump creation is in progress."
req_data='{"DiagnosticDataType": "Manager"}'
req_path="/redfish/v1/Managers/HGX_BMC_0/LogServices/Dump/Actions/LogService.CollectDiagnosticData"
output=$(curl --fail -sS -d "${req_data}" -X POST http://${HMC_IP}${req_path} 2>&1)
exit_code=$?
if [[ $exit_code -ne 0 ]] && echo "$output" | grep -Eq "error: 503"; then
    echo "Expected HTTP error code 503 obtained."
    echo "TC result: PASSED"
else
    error "When previous dump creation is in progress, expected Redfish HTTP code is 503. Redfish output: $output"
fi
echo ""

echo "$(date) Waitng for the dump($entry_id) creation to complete."
timeout=$((30*60)) # 30min timeout for creating a dump
start_time=$(get_time)
while true; do
    if [[ $(($(get_time) - start_time)) -ge $timeout ]]; then
        error "Waitng for for the dump generation more than $((timeout/60)) min."
    fi
    if ! output=$($TOOL_DIR/execute_command.sh 2 "$DUMP_TYPE $entry_id_hex"); then
        echo "ERROR: $output"
    else
        status=$(echo "$output" | cut -d ' ' -f 1)
        if [[ "$status" == "0x01" ]]; then
            break
        fi
    fi
    sleep 5
done
echo "$(date) Dump($entry_id) completed."
echo ""

echo "$(date) I2C_DUMP_4 - I2C Dump download without dump creation."
echo "Request for block 0 from dump with entry id 0xFF 0x${entry_id_hex:2:2}."
if ! output=$($TOOL_DIR/execute_command.sh 3 "$DUMP_TYPE 0xFF 0x${entry_id_hex:2:2} 0x00 0x00"); then
    echo "Error returned."
    echo "TC result: PASSED"
fi
echo ""

echo "$(date) I2C_DUMP_4 - Request file block data with a wrong block number."
echo "Request for block 0xFFFF from dump with entry id $entry_id."
if ! output=$($TOOL_DIR/execute_command.sh 3 "$DUMP_TYPE $entry_id_hex 0xFF 0xFF"); then
    echo "Error returned."
    echo "TC result: PASSED"
fi
echo ""

echo "$(date) Turn off i2c dump server on HMC..."
if ! i2ctransfer -y 1 w2@0x45 0x00 0x06; then
    error "Cannot stop i2c dump server on HMC."
fi
echo ""

echo "Test result: PASSED"

