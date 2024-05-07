#!/bin/bash

# Copyright (c) 2024, NVIDIA CORPORATION.  All rights reserved.
#
#  NVIDIA CORPORATION and its licensors retain all intellectual property
#  and proprietary rights in and to this software, related documentation
#  and any modifications thereto.  Any use, reproduction, disclosure or
#  distribution of this software and related documentation without an express
#  license agreement from NVIDIA CORPORATION is strictly prohibited.


app_name="cper_dump.sh"
app_ver="0.2"

CPERPARSER="cperparse"

TMP_DIR="/tmp"
EPOCHTIME=$(date +"%s")
F_NAME=""
TMP_DIR_PATH=""

ARG_DUMP_ID="00000000"
ARG_DUMP_PATH=""
ARG_DIAG_DATA=""

logger() #(msg)
{
    echo "$app_name: $@"
}

help()
{
    echo ""
    echo "This script is used to collect CPER blob to compressed file"
    echo "Creates compressed archive with CPER blob in given path"
    echo "Archive name pattern <path>/obmcdump_<ID>_<EPOCH>"
    echo "Version: $app_ver"
    echo ""
    echo "Usage: $app_name [-h] [-D] -p <file_path> -s <file_path> [-i <dump_id>]"
    echo ""
    echo "Options:"
    echo "          -h  shows this help"
    echo "          -p  (required) path to put compressed dump to"
    echo "          -s  (required) file path to source of cper blob"
    echo "          -i  file dump id, default $ARG_DUMP_ID"

}

initialize()
{
    local rc=0

    F_NAME=$"obmcdump_"$ARG_DUMP_ID"_$EPOCHTIME"
    TMP_DIR_PATH="$TMP_DIR/$F_NAME"

    mkdir -p $ARG_DUMP_PATH;rc=$?
    if [ "$rc" -ne 0 ]; then
        logger "Failed to create destination directory [$ARG_DUMP_PATH], rc=$rc!"
        return $rc
    fi
    echo "Created destination directory [$ARG_DUMP_PATH]."

    mkdir -p $TMP_DIR_PATH;rc=$?
    if [ "$rc" -ne 0 ]; then
        logger "Failed to create tmp work directory [$TMP_DIR_PATH], rc=$rc!"
        return $rc
    fi
    echo "Created tmp work directory [$TMP_DIR_PATH]."

    cd $ARG_DUMP_PATH
    local dec_dir=$ARG_DUMP_PATH/Decoded
    mkdir -p $dec_dir;rc=$?
    if [ "$rc" -ne 0 ]; then
        logger "Failed to create decoded CPER directory [$dec_dir], rc=$rc!"
        return $rc
    fi
    echo "Created decoded CPER directory [$dec_dir]."

    #Call CPER Decoded binary to decode the error log
    if command -v $CPERPARSER >/dev/null 2>&1; then
        $CPERPARSER --redfish $ARG_DIAG_DATA --json $dec_dir/decoded.json;rc=$?
        if [ "$rc" -ne 0 ]; then
            logger "Do $CPERPARSER on [$ARG_DIAG_DATA] failed, rc=$rc!"
            return $rc
        fi
    else
        rc=$?
        logger "$CPERPARSER not found, rc=$rc! Please make sure nvidia-cperdecoder module is in OBMC_IMAGE_EXTRA_INSTALL of this platform recipe."
        return $rc
    fi

    mv $ARG_DIAG_DATA $TMP_DIR_PATH
    return 0
}

cleanup()
{
    local rc=0

    rm -rf $TMP_DIR_PATH;rc=$?
    if [ "$rc" -ne 0 ]; then
        logger "Cannot remove [$TMP_DIR_PATH], rc=$rc!"
    fi

    rm -rf $TMP_DIR_PATH.tar.xz;rc=$?
    if [ "$rc" -ne 0 ]; then
        logger "Cannot remove [$TMP_DIR_PATH.tar.xz], rc=$rc!"
    fi

    return $rc
}

main()
{
    local rc=0
    # compress intermediate dir to archive
    local tar_file=$TMP_DIR_PATH.tar.xz
    tar -Jcf $tar_file -C "${TMP_DIR_PATH%/*}" "${TMP_DIR_PATH##*/}";rc=$?
    if [ "$rc" -ne 0 ]; then
        logger "Compressing [$tar_file] failed, rc=$rc!"
        return $rc
    fi

    # cp compressed archive to destination dir
    cp $tar_file $ARG_DUMP_PATH;rc=$?
    if [ "$rc" -ne 0 ]; then
        logger "Failed to copy [$tar_file] to [$ARG_DUMP_PATH], rc=$rc!"
        return $rc
    fi

    return 0
}

# MAIN #
while getopts ":hp:s:i:" option; do
    case $option in
    h) # display help
        help
        exit 1
        ;;

    p) # output file path
        ARG_DUMP_PATH=$OPTARG
        if [ -z "$ARG_DUMP_PATH" ]; then
            logger "Missing argument for option -p."
            exit 1
        fi
        ;;

    i) # dump id
        if [ -z "$OPTARG" ]; then
            logger "Missing argument for option -i."
            exit 1
        fi
        ARG_DUMP_ID=$OPTARG
        ;;

    s) # source file path
        ARG_DIAG_DATA=$OPTARG
        if [ -z "$ARG_DIAG_DATA" ]; then
            logger "Missing argument for option -s."
            exit 1
        fi
        ;;

    \?) # Invalid option
        logger "Invalid option: -$OPTARG" >&2
        help
        exit 1
        ;;

    :)
        logger "Missing option argument for -$OPTARG" >&2
        exit 1
        ;;

    *)
        logger "Unimplemented option: -$OPTARG" >&2
        exit 1
        ;;
    esac
done

if [ $OPTIND -eq 1 ]; then
    logger "No options were passed."
    exit 1
fi

rc=0

initialize;rc=$?
if [ "$rc" -ne 0 ]; then
    logger "Init failed, rc=$rc!"
    cleanup
    exit $rc
fi

main;rc=$?
if [ "$rc" -ne 0 ]; then
    logger "Dump failed, rc=$rc!"
fi

cleanup;rc=$?
if [ "$rc" -ne 0 ]; then
    logger "Cleanup failed, rc=$rc!"
    exit $rc
fi

exit 0
