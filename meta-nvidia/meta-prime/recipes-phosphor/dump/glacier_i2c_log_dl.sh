#!/bin/bash
BUS=$1
ADD=$2
FILENAME=$3

log_v0 () {
    local size_hex=5800
    if [ -x "$(command -v bc)" ]; then
        local size=$(echo "ibase=16; ${size_hex}" | bc)
    else
        local size=$(( 16#$size_hex ))
    fi
    > ${FILENAME}
    i2ctransfer -y ${BUS} w1@${ADD} 0x05 > /dev/null || { exit 1; }
    local i=1
    while [ ${i} -le ${size} ]; do
        printf "download: %d/%d\r" ${i} ${size}
        i2ctransfer -y ${BUS} w1@${ADD} 0x06 r16 >> ${FILENAME} || { exit 1; }
        i=$(( i + 1 ))
    done
    printf "\nDone\n"
}

log_v1 () {
    # parse size
    local event_size_hex=$(echo ${1} | sed 's/0x//g' | awk '{print toupper($2$1)}')
    local fault_size_hex=$(echo ${1} | sed 's/0x//g' | awk '{print toupper($4$3)}')
    if [ -x "$(command -v bc)" ]; then
        local event_size=$(echo "ibase=16; ${event_size_hex}" | bc)
        local fault_size=$(echo "ibase=16; ${fault_size_hex}" | bc)
    else
        local event_size=$(( 16#$event_size_hex ))
        local fault_size=$(( 16#$fault_size_hex ))
    fi
    printf "event size is %d, fault size is %d\n" ${event_size} ${fault_size}
    echo "${1}" > ${FILENAME}
    # Download event log
    local i=1
    while [ ${i} -le ${event_size} ]; do
        printf "download event: %d/%d\r" ${i} ${event_size}
        i2ctransfer -y ${BUS} w1@${ADD} 0x06 r16 >> ${FILENAME} || { exit 1; }
        i=$(( i + 1 ))
    done
    printf "\n"
    # Download fault log
    i=1
    while [ ${i} -le ${fault_size} ]; do
        printf "download fault: %d/%d\r" ${i} ${fault_size}
        local x=1
        while [ ${x} -le 4 ]; do
            i2ctransfer -y ${BUS} w1@${ADD} 0x06 r16 >> ${FILENAME} || { exit 1; }
            x=$(( x + 1 ))
        done
        i=$(( i + 1 ))
    done
    printf "\nDone\n"
}

# check arguments
if [ $# -lt 3 ]; then
    echo "Glacier i2c log download tool - version 0.0.1"
    echo "Usage  : $0 I2C_BUS I2C_ADDRESS OUTPUT_FILE_NAME"
    echo "Example: $0 1 0x52 glacier_log.txt"
    exit 1
fi

# check log version
metadata=$(i2ctransfer -y ${BUS} w1@${ADD} 0x05 r16) || { exit 1; }
version=$(echo ${metadata} | sed 's/0x//g' | awk '{print toupper($16)}')
if [ "${version}" == "FF" ]; then
    echo "Log version is 0"
    log_v0
elif [ "${version}" == "01" ]; then
    echo "Log version is 1"
    log_v1 "${metadata}"
else
    echo "Unsupported version: ${version}"
    exit 1
fi
