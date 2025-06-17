#!/bin/bash

FPGA0_BUS=${1:-1}
FPGA1_BUS=${2:-2}
TIMEOUT_S="${3:-60}"

# these are from the Glacier Firmware Design Document
NOT_AUTHENTICATED=0
AUTH_SUCCESS=1
VALIDATE_PUBLIC_KEY_ERR=2
KEY_REVOKE_CHECK_ERR=3
ROLLBACK_PROTECTION_CHECK_ERR=4
AUTH_ERR=6
SPI_READY_ERR=7
AUTH_IN_PROGRESS=15

# this isn't in any spec. just used to indicate next steps
EROT_NOT_READY=50
EROT_AUTH_IN_PROGRESS=51
EROT_AUTH_FAILED=52

get_erot_auth_status()
{
    status=$1
    bus=$2
    spi=$3

    case $status in
        $NOT_AUTHENTICATED)
            cc=$EROT_AUTH_IN_PROGRESS
            ;;
        $AUTH_SUCCESS)
            cc=0
            ;;
        $VALIDATE_PUBLIC_KEY_ERR)
            echo "[ERROR] $bus-$spi: Key hash does not match"
            cc=$EROT_AUTH_FAILED
            ;;
        $KEY_REVOKE_CHECK_ERR)
            echo "[ERROR] $bus-$spi: The key is revoked"
            cc=$EROT_AUTH_FAILED
            ;;
        $ROLLBACK_PROTECTION_CHECK_ERR)
            echo "[ERROR] $bus-$spi: Image version is revoked"
            cc=$EROT_AUTH_FAILED
            ;;
        $AUTH_ERR)
            echo "[ERROR] $bus-$spi: Signature verification failed"
            cc=$EROT_AUTH_FAILED
            ;;
        $SPI_READY_ERR)
            echo "[ERROR] $bus-$spi: Failed to read spi during authentication"
            cc=$EROT_AUTH_FAILED
            ;;
        $AUTH_IN_PROGRESS)
            cc=$EROT_AUTH_IN_PROGRESS
            ;;
        *)
            echo "[ERROR] $bus-$spi: Unknown error: $status"
            cc=$EROT_AUTH_FAILED
            ;;
    esac

    return $cc
}

check_cpu_erot_auth()
{
    local BUS=$1

    #enable direct access to the erot
    i2ctransfer -y $BUS w2@0x60 0xc0 0x01

    #query erot boot status
    local cmd_output=$(i2ctransfer -y $BUS w1@0x28 0x14 r10)

    #command status is the second byte of the command output
    local cmd_status=$(echo $cmd_output | awk '{print $2}')
    if [ "$cmd_status" != "0x00" ]; then
        echo "[WARNING] Boot status query command returned error ${cmd_status}, retrying."
        return $EROT_NOT_READY
    fi

    #disable direct access to the erot after we are done
    i2ctransfer -y $BUS w2@0x60 0xc0 0x00

    #auth status is bit 8-15 of Boot Status Code. Obtain from command output
    auth_status=$(echo $cmd_output | awk -v byte=9 '{print $byte}')

    #parsing for primary and secondary firmware authentication status as defined
    #in the Glacier Firmware Design Document
    local sec_fw_auth_status=$(echo $(($auth_status >> 4)))
    local pri_fw_auth_status=$(echo $(($auth_status & 0x0F)))

    get_erot_auth_status $pri_fw_auth_status $BUS "primary"
    cc=$?
    if [ $cc -ne 0 ]; then
        return $cc
    fi

    get_erot_auth_status $sec_fw_auth_status $BUS "secondary"
    cc=$?
    if [ $cc -ne 0 ]; then
        return $cc
    fi
    return 0
}

start_time=$(date +%s)
timeout_time=$((start_time + TIMEOUT_S))
current_time=$start_time

while [ $current_time -lt $timeout_time ]
do
    check_cpu_erot_auth $FPGA0_BUS
    bus0_cc=$?
    check_cpu_erot_auth $FPGA1_BUS
    bus1_cc=$?

    if [ $bus0_cc -eq 0 ] && [ $bus1_cc -eq 0 ]; then
        echo "ERoT auth for both CPUs completed successfully"
        exit 0
    fi

    if [ $bus0_cc -eq $EROT_AUTH_FAILED ]; then
        echo "[ERROR] $FPGA0_BUS: Failed ERoT authentication"
        # dump here
        exit 1
    fi

    if [ $bus1_cc -eq $EROT_AUTH_FAILED ]; then
        echo "[ERROR] $FPGA1_BUS: Failed ERoT authentication"
        # dump here
        exit 1
    fi

    echo "ERoT auth not complete. BUS0: $bus0_cc BUS1: $bus1_cc"
    current_time=$(date +%s)

    sleep 0.5
done

echo "Reached timeout $TIMEOUT_S and failed to authenticate. BUS0: $bus0_cc BUS1: $bus1_cc"
exit 1