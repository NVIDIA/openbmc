#!/bin/bash

get_time() {
    cat /proc/uptime | cut -d ' ' -f 1 | sed 's/\..*//'
}

hex_to_dec() {
    hex_value="$1"
    stripped_hex=$(echo "$hex_value" | sed 's/0x\| //g' | awk '{print toupper($0)}')
    echo "ibase=16; $stripped_hex" | bc
}
