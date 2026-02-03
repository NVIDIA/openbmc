#!/bin/bash

# Test covers test id I2C_DUMP_1 and I2C_DUMP_2

TOOL_DIR=$(dirname $(dirname $0))
if [[ $TOOL_DIR == "." ]]; then
    TOOL_DIR=".."
fi

DETAILED_LOG="detailed_log.txt"

print_summary() {
    dump_path="$1"

    dump_size=$(ls -l $dump_path | awk '{print $5}')
    creation_time=$(cat "$DETAILED_LOG" | grep "Creation time:" | sed 's/.*Creation time://' | sed 's/[^0-9]//g')
    download_time=$(cat "$DETAILED_LOG" | grep "Download time:" | sed 's/.*Download time://' | sed 's/[^0-9]//g')

    echo "$dump_name succesfully created. Dump size: $dump_size bytes. Creation time: $((creation_time/60)) min $((creation_time%60)) sec. Download time: $((download_time/60)) min $((download_time%60)) sec."
    echo ""
}


opcode=1
dump_name="hmc_dump.tar.xz"
echo "Start TestCase 1. Opcode $opcode. Dump name: $dump_name. Execution details you can see in $DETAILED_LOG"
if ! $TOOL_DIR/i2c_dump_util.sh $opcode $dump_name > $DETAILED_LOG; then
    echo "Failed to download $dump_name over i2c. Error msg: $(cat $DETAILED_LOG)"
    exit 1
fi
print_summary "$dump_name"

opcode=2
dump_name="fpga_register_dump.tar.xz"
echo "Start TestCase 2. Opcode $opcode. Dump name: $dump_name. Execution details you can see in $DETAILED_LOG"
if ! $TOOL_DIR/i2c_dump_util.sh $opcode $dump_name > $DETAILED_LOG; then
    echo "Failed to download $dump_name over i2c. Error msg: $(cat $DETAILED_LOG)"
    exit 1
fi
print_summary "$dump_name"

opcode=3
dump_name="erot_data.tar.xz"
echo "Start TestCase 3. Opcode $opcode. Dump name: $dump_name. Execution details you can see in $DETAILED_LOG"
if ! $TOOL_DIR/i2c_dump_util.sh $opcode $dump_name > $DETAILED_LOG; then
    echo "Failed to download $dump_name over i2c. Error msg: $(cat $DETAILED_LOG)"
    exit 1
fi
print_summary "$dump_name"

echo "All dumps downloaded succesffully. Please verify manually if the dumps are correct."
