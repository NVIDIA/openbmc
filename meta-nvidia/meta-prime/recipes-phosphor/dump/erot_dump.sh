#!/bin/bash

TMP_DIR="/tmp"
EPOCHTIME=$(date +"%s")
F_NAME_TEMPLATE=""
TMP_DIR_PATH=""
OUTPUT_ARCHIVE_PATH=""

ARG_DUMP_ID="00000000"
ARG_DUMP_PATH=""

DUMP_CFG_INPUT_FILE="/usr/share/device_mctp_eid.csv"
GLACIER_LOG_FILE="/var/mctp-vdm-output.bin"

function help()
{
    echo "Usage: erot_dump [-h] -p <file_path> -i <dump_id>"
    echo ""
    echo "Options:"
    echo "          -h  shows this help"
    echo "          -p  (required) path to put compressed dump to"
    echo "          -i  file dump id, default $ARG_DUMP_ID"
}


function initialize()
{
    F_NAME_TEMPLATE=$"obmcdump_"$ARG_DUMP_ID"_$EPOCHTIME"
    TMP_DIR_PATH="$TMP_DIR/$F_NAME_TEMPLATE"
    OUTPUT_ARCHIVE_PATH="$TMP_DIR/$F_NAME_TEMPLATE.tar.xz"

    mkdir -p $ARG_DUMP_PATH
    if [ $? -ne 0 ]; then
        echo "Failed to create destination directory $ARG_DUMP_PATH"
        exit 1
    fi
    echo "Created dest dir $ARG_DUMP_PATH"

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

    if [ -e "$TMP_DIR_PATH" ]; then
        rm -r $TMP_DIR_PATH
        if [ $? -ne 0 ]; then
            echo "Cannot remove $TMP_DIR_PATH"
            res_ret=1
        fi
    fi

    if [ -e "$OUTPUT_ARCHIVE_PATH" ]; then
        rm -r $OUTPUT_ARCHIVE_PATH
        if [ $? -ne 0 ]; then
            echo "Cannot remove $OUTPUT_ARCHIVE_PATH"
            res_ret=1
        fi
    fi

    return $res_ret
}

function main()
{
    DEVICENAME_EID_LIST=`cat "$DUMP_CFG_INPUT_FILE"`

    for device_eid in $DEVICENAME_EID_LIST
    do
        local name=$(echo $device_eid | cut -f1 -d,)
        eid=$(echo $device_eid | cut -f2 -d,)
        rm -f $GLACIER_LOG_FILE
        cmddump="/usr/bin/mctp-vdm-util -c download_log -t ${eid}"
        # echo $name_$eid > $GLACIER_LOG_FILE ; rc=$?
        ${cmddump}; rc=$?
        if [ $rc -ne 0 ]; then
            echo "An error occured while running $cmddump"
        fi
        tmpFileName="${name}_erot_dump.bin"
        mv -f $GLACIER_LOG_FILE "$TMP_DIR_PATH/$tmpFileName"
    done

    # compress intermediate dir to archive
    tar -Jcf $OUTPUT_ARCHIVE_PATH -C $(dirname "$TMP_DIR_PATH") \
        $(basename "$TMP_DIR_PATH")

    if [ $? -ne 0 ]; then
        echo "Compression $OUTPUT_ARCHIVE_PATH failed"
        return 1
    fi

    # cp compressed archive to destination dir
    cp $OUTPUT_ARCHIVE_PATH $ARG_DUMP_PATH
    if [ $? -ne 0 ]; then
        echo "Failed to copy $OUTPUT_ARCHIVE_PATH to $ARG_DUMP_PATH"
        return 1
    fi

    return 0
}

while getopts ":hDp:i:" option; do
   case $option in
      h) # display help
         help
         exit;;

      p) # output file path
         ARG_DUMP_PATH=$OPTARG
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

if [ ! "$ARG_DUMP_PATH" ]; then
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
