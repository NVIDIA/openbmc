#!/bin/bash

exec {lock_fd}>/var/lock/selftest_tool_lockfile || exit 1
flock -n "$lock_fd" || { echo "ERROR: cannot start another instance of selftest_tool, wait for previous to finish." >&2; exit 1; }

TMP_DIR="/tmp"
EPOCHTIME=$(date +"%s")
F_NAME=""
TMP_DIR_PATH=""

ARG_DUMP_ID="00000000"
ARG_VERBOSE=''
ARG_SELFTEST_DUMP_PATH=''

if [ -z "$AML_DAT" ] && CFG_DAT_FILE_PATH="/run/initramfs/ro/usr/share/oobaml/dat.json" || CFG_DAT_FILE_PATH=$AML_DAT

CFG_DAT_FILE_PATH="/run/initramfs/ro/usr/share/oobaml/dat.json"
CFG_SELFTEST_TOOL_PATH="/usr/bin/selftest_tool"


function help()
{
    echo ""
    echo "Creates compressed archive with OOBAML selftest report in given path"
    echo "Archive name pattern <path>/obmcdump_<ID>_<EPOCH>"
    echo "Takes $CFG_DAT_FILE_PATH Device Association Tree for selftest_tool"
    echo "Usage: selftest_dump.sh [-h] [-v] -p <file_path> -i <dump_id>"
    echo ""
    echo "Options:"
    echo "          -h  shows this help"
    echo "          -p  (required) path to put compressed dump to"
    echo "          -i  file dump id, default $ARG_DUMP_ID"
    echo "          -v  verbose; do not hide dump errors"
}

function dump_selftest()
{
    local CMD_RUN="$CFG_SELFTEST_TOOL_PATH -d $CFG_DAT_FILE_PATH \
-r $TMP_DIR_PATH/selftest_report.json"

    echo "Executing: $CMD_RUN"

    if [ $ARG_VERBOSE ]; then
        $CMD_RUN
    else
        #hidden errors if no dbg mode enabled\
        $CMD_RUN >/dev/null 2>&1
    fi

    # $CMD_RUN
    if [ $? -ne 0 ]; then
        echo "Selftest dump failed"
        return 1
    fi

    return 0
}

function initialize()
{
    F_NAME=$"obmcdump_"$ARG_DUMP_ID"_$EPOCHTIME"
    TMP_DIR_PATH="$TMP_DIR/$F_NAME"

    mkdir -p $ARG_SELFTEST_DUMP_PATH
    if [ $? -ne 0 ]; then
        echo "Failed to create destination directory $ARG_SELFTEST_DUMP_PATH"
        exit 1
    fi
    echo "Created dest dir $ARG_SELFTEST_DUMP_PATH"

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
    dump_selftest
    if [ $? -ne 0 ]; then
        echo "Dump selftest report failed"
        return 1
    fi

    tar -Jcf $TMP_DIR_PATH.tar.xz -C $(dirname "$TMP_DIR_PATH") $(basename "$TMP_DIR_PATH")
    if [ $? -ne 0 ]; then
        echo "Compression $TMP_DIR_PATH.tar.xz failed"
        return 1
    fi

    cp $TMP_DIR_PATH.tar.xz $ARG_SELFTEST_DUMP_PATH
    if [ $? -ne 0 ]; then
        echo "Failed to copy $TMP_DIR_PATH.tar.xz to $ARG_SELFTEST_DUMP_PATH"
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
         ARG_SELFTEST_DUMP_PATH=$OPTARG
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

if [ ! "$ARG_SELFTEST_DUMP_PATH" ]; then
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
