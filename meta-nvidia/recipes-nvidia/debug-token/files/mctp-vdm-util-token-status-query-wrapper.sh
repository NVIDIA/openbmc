#!/bin/bash

info() {
    echo -e \
        "Usage: $(basename $0) <EID1> <EID2> ...\n" \
        "Executes debug token query for all provided MCTP EIDs.\n" \
        "If query version 2 results in an error, query version 1 is performed.\n" \
        "For each query, the output uses the following format:\n" \
        "<EID>;<query version>;<TX data>;<RX data>" >&2
}

run_query() {
    local RXDATA=""
    local TXDATA=""
    local ERRORCODE=00
    local TIMEOUT=3
    VER=${1}
    EID=${2}
    if [[ "${VER}" == "1" ]]; then
        COMMAND="debug_token_query"
    elif [[ "${VER}" == "2" ]]; then
        COMMAND="debug_token_query_v2"
    elif [[ "${VER}" == "3" ]]; then
        COMMAND="debug_token_query_v3"
    else
       return
    fi
    OUTPUT=$(/usr/bin/mctp-vdm-util -o ${TIMEOUT} -c ${COMMAND} -t ${EID})
    RX=$(echo "${OUTPUT}" | grep "RX: ")
    TX=$(echo "${OUTPUT}" | grep "TX: ")
    if ! [[ -z "${TX}" ]]; then
        TXDATA=$(echo ${TX:4} | awk '{$1=$1};1')
    fi
    if ! [[ -z "${RX}" ]]; then
        RXDATA=$(echo ${RX:4} | awk '{$1=$1};1')
        RXBYTES=$(echo ${RXDATA} | wc -w)
        if [[ ${RXBYTES} == 9 ]]; then
            # error code = last byte of the RX data
            ERRORCODE=${RXDATA##* }
        fi
    else
        # RX data is missing, indicate an error
        ERRORCODE=01
    fi
    echo "${EID};${VER};${TXDATA};${RXDATA}"
    return $((16#${ERRORCODE}))
}

if [[ $# == 0 ]] ; then
    info
    exit 0
fi

for EID in "$@"; do
    NUMRE='^[0-9]+$'
    if ! [[ ${EID} =~ $NUMRE ]]; then
        echo "Argument ${EID} is not a number, ignoring." >&2
        continue
    fi
    for VER in 3 2 1; do
        run_query ${VER} ${EID}
        RC=$?
        if [[ ${RC} == 0 ]]; then
            break
        fi
    done
done
