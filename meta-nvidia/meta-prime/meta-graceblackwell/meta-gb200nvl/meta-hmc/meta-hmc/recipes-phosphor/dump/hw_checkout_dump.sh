#!/bin/bash

TMP_DIR="/tmp"
EPOCHTIME=$(date +"%s")
F_NAME=""
TMP_DIR_PATH=""

ARG_DUMP_ID="00000000"
ARG_VERBOSE=''
ARG_HWCHECKOUT_DUMP_PATH=''

CFG_CHECKOUT_TOOL_PATH="/usr/bin/hw_checkout.sh"
CFG_CHECKOUT_TOOL_LOG="hmc_checker.log"


function help()
{
    echo ""
    echo "Creates compressed archive with Hardware Checkout report in a given path"
    echo "Archive name pattern <path>/obmcdump_<ID>_<EPOCH>"
    echo "Usage: hw_checkout_dump.sh [-h] [-v] -p <file_path> -i <dump_id>"
    echo ""
    echo "Options:"
    echo "          -h  shows this help"
    echo "          -p  (required) path to put compressed dump to"
    echo "          -i  file dump id, default $ARG_DUMP_ID"
    echo "          -v  verbose; do not hide dump errors"
}

function dump_hwcheckout()
{
    local CMD_RUN="$CFG_CHECKOUT_TOOL_PATH hmc fpga gpu"

    echo "Executing: $CMD_RUN"

    if [ $ARG_VERBOSE ]; then
        $CMD_RUN > $TMP_DIR_PATH/console.log 2>/dev/null
    else
        #hidden errors if no dbg mode enabled\
        $CMD_RUN > $TMP_DIR_PATH/console.log
    fi

    cp $TMP_DIR/$CFG_CHECKOUT_TOOL_LOG $TMP_DIR_PATH

    if [ $? -ne 0 ]; then
        echo "Hardware checkout dump failed"
        return 1
    fi

    return 0
}

function initialize()
{
    F_NAME=$"obmcdump_"$ARG_DUMP_ID"_$EPOCHTIME"
    TMP_DIR_PATH="$TMP_DIR/$F_NAME"

    mkdir -p $ARG_HWCHECKOUT_DUMP_PATH
    if [ $? -ne 0 ]; then
        echo "Failed to create destination directory $ARG_HWCHECKOUT_DUMP_PATH"
        exit 1
    fi
    echo "Created dest dir $ARG_HWCHECKOUT_DUMP_PATH"

    mkdir -p $TMP_DIR_PATH
    if [ $? -ne 0 ]; then
        echo "Failed to create temp work directory $TMP_DIR_PATH"
        exit 1
    fi
    echo "Created tmp work dir $TMP_DIR_PATH"
}


function cleanup()
{
    local res_ret=0
    rm -r $TMP_DIR_PATH
    if [ $? -ne 0 ]; then
        echo "Cannot remove $TMP_DIR_PATH"
        res_ret=1
    fi

    rm -r $TMP_DIR_PATH.tar.xz
    if [ $? -ne 0 ]; then
        echo "Cannot remove $TMP_DIR_PATH.tar.xz"
        res_ret=1
    fi

    return $res_ret
}


function main()
{
    dump_hwcheckout
    if [ $? -ne 0 ]; then
        echo "Dump hardware checkout report failed"
        return 1
    fi

    tar -Jcf $TMP_DIR_PATH.tar.xz -C $(dirname "$TMP_DIR_PATH") $(basename "$TMP_DIR_PATH")
    if [ $? -ne 0 ]; then
        echo "Compression $TMP_DIR_PATH.tar.xz failed"
        return 1
    fi

    cp $TMP_DIR_PATH.tar.xz $ARG_HWCHECKOUT_DUMP_PATH
    if [ $? -ne 0 ]; then
        echo "Failed to copy $TMP_DIR_PATH.tar.xz to $ARG_HWCHECKOUT_DUMP_PATH"
        return 1
    fi

    return 0
}

while getopts ":hvp:i:" option; do
   case $option in
      h) # display help
         help
         exit;;

      v) # allow dbg messages
         ARG_VERBOSE=1
         ;;

      p) # output file path
         ARG_HWCHECKOUT_DUMP_PATH=$OPTARG
         ;;

      i) # output file path
         ARG_DUMP_ID=$OPTARG
         ;;

     \?) # Invalid option
         echo "Invalid option: -$OPTARG" >&2
         help
         exit 1
         ;;

      :) echo "Missing option argument for -$OPTARG" >&2
         exit 1
         ;;

      *) echo "Unimplemented option: -$OPTARG" >&2
         exit 1
         ;;
   esac
done

if [ $OPTIND -eq 1 ]; then
    echo "No options were passed"
    WRONG_OPT=1
fi

if [ ! "$ARG_HWCHECKOUT_DUMP_PATH" ]; then
    echo "argument -p is required"
    WRONG_OPT=1
fi

if [ $WRONG_OPT ]; then
    help
    exit 1
fi

initialize
if [ $? -ne 0 ]; then
    echo "Init failed"
    exit 1
fi

main
if [ $? -ne 0 ]; then
    echo "Dump failed"
    cleanup
    exit 1
fi

cleanup
if [ $? -ne 0 ]; then
    echo "Cleanup failed"
    exit 1
fi

exit 0
