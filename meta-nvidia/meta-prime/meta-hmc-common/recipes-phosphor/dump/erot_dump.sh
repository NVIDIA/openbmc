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
CMS_LOG_FILE="/var/cms2_log.bin"

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

# Function to get the subtree paths
function get_subtree_paths() {
  busctl call -j xyz.openbmc_project.ObjectMapper /xyz/openbmc_project/object_mapper xyz.openbmc_project.ObjectMapper GetSubTree sias /xyz/openbmc_project/inventory/system/recovery_config/OCP_Recovery_Devices 0 1 xyz.openbmc_project.Configuration.OCPRecovery --json=pretty
}

# Function to extract paths from JSON
function extract_paths() {
  local json=$1
  local IFS=$'\n'
  local paths=()
  for line in $json; do
    if [[ $line =~ \"(/xyz/openbmc_project/inventory/system/recovery_config/OCP_Recovery_Devices/[^\"]*)\" ]]; then
      paths+=("${BASH_REMATCH[1]}")
    fi
  done
  echo "${paths[@]}"
}

# Function to get properties for a given path
function get_properties() {
    local path=$1

    name=$(busctl get-property xyz.openbmc_project.EntityManager "$path" xyz.openbmc_project.Configuration.OCPRecovery Name 2>/dev/null)
    i2c_address=$(busctl get-property xyz.openbmc_project.EntityManager "$path" xyz.openbmc_project.Configuration.OCPRecovery I2CAddress 2>/dev/null)
    i2c_bus=$(busctl get-property xyz.openbmc_project.EntityManager "$path" xyz.openbmc_project.Configuration.OCPRecovery I2CBus 2>/dev/null)

    name=${name#* }
    name=$(echo "$name" | tr -d '"')
    # Extract the desired part of the name
    name=$(echo "$name" | sed -e 's/^.*_\(GPU_[0-9]*\)$/\1/')
    i2c_address=${i2c_address#* }
    i2c_bus=${i2c_bus#* }

    if [[ -z $name || -z $i2c_address || -z $i2c_bus ]]; then
        echo "Error: One or more properties are empty for path: $path"
        return 1
    fi

    echo "$name,$i2c_address,$i2c_bus"
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

		# Get ERoT boot status and log the fatal err status code to file
        bootstatus=`/usr/bin/mctp-vdm-util -c query_boot_status -t ${eid} | grep RX`
        bootStatusFatalErrFileName="$TMP_DIR_PATH/${name}_erot_boot_status_fatal_errcode.log"
        bootStatusRxArr=($bootstatus)
        bootStatusFatalErrCode=${bootStatusRxArr[${#bootStatusRxArr[@]}-4]}
        echo "$bootStatusFatalErrCode" > $bootStatusFatalErrFileName

        querryBootTmpFileName="${name}_query_boot_status.log"
        /usr/bin/mctp-vdm-util -c query_boot_status -t ${eid} -m -j &>> $querryBootTmpFileName
        if [ $? -ne 0 ]; then
            echo "An error occured while running query_boot_status for eid ${eid}"
        fi
        mv -f $querryBootTmpFileName $TMP_DIR_PATH
    done

    response=$(get_subtree_paths)
    paths=$(extract_paths "$response")

    for path in $paths 
    do
        properties=$(get_properties "$path")
            if [[ $? -eq 0 ]]; then
                  # Split the properties into variables
                    IFS=',' read -r deviceName i2c_address i2c_bus <<< "$properties"
                    echo "ocp-recovery-tool GetDeviceStatus for the ${deviceName} on i2c bus ${i2c_bus} and i2c address ${i2c_address}" &>> "${deviceName}.log"
                    /usr/bin/ocp-recovery-tool GetDeviceStatus -b $i2c_bus -s $i2c_address &>> "${deviceName}.log"
                    if [ $? -ne 0 ]; then
                        echo "ocp-recovery-tool GetDeviceStatus failed for the ${deviceName} on i2c bus ${i2c_bus} and i2c address ${i2c_address}"
                    fi
                    echo "ocp-recovery-tool GetRecoveryStatus for the ${deviceName} on i2c bus ${i2c_bus} and i2c address ${i2c_address}" &>> "${deviceName}.log"
                    /usr/bin/ocp-recovery-tool GetRecoveryStatus -b $i2c_bus -s $i2c_address &>> "${deviceName}.log"
                    if [ $? -ne 0 ]; then
                        echo "ocp-recovery-tool GetRecoveryStatus failed for the ${deviceName} on i2c bus ${i2c_bus} and i2c address ${i2c_address}" &>> "${deviceName}.log"
                    fi
                    rm -f $CMS_LOG_FILE
                    cmsTmpFileName="${deviceName}_CMS.bin"
                    echo "ocp-recovery-tool GetCMSLogs for the ${deviceName} on i2c bus ${i2c_bus} and i2c address ${i2c_address}" &>> "${deviceName}.log"
                    /usr/bin/ocp-recovery-tool GetCMSLogs -b $i2c_bus -s $i2c_address -w 2 &>> "${deviceName}.log"
                    if [ $? -ne 0 ]; then
                        echo "ocp-recovery-tool GetCMSLogs failed for the ${deviceName} on i2c bus ${i2c_bus} and i2c address ${i2c_address}"
                    fi
            fi
        mv -f "${deviceName}.log" "$TMP_DIR_PATH"
        mv -f "$CMS_LOG_FILE" "$TMP_DIR_PATH/$cmsTmpFileName"
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
