#!/bin/bash

TMP_DIR="/tmp"
EPOCHTIME=$(date +"%s")
F_NAME_TEMPLATE=""
TMP_DIR_PATH=""
OUTPUT_ARCHIVE_PATH=""

ARG_DUMP_ID="00000000"
ARG_DBG_MODE=false
ARG_FPGA_DUMP_PATH=""

I2C_DUMP_CFG_INPUT_FILE="/usr/share/fpga_register_table_info.csv"
I2C_DUMP_IDX=""
I2C_BUS_HMC=""
I2C_ADDR_SLAVE=""
I2C_ADDR_REG=""
I2C_ADDR_PAGE=""
I2C_DUMP_SIZE=""
I2C_GET_REG_CMD=""

function help()
{
    echo ""
    echo "This script is used to dump FPGA registers to compressed file"
    echo "Creates compressed archive with fpga dump in given path"
    echo "Archive name pattern <path>/obmcdump_<ID>_<EPOCH>"
    echo "Takes $I2C_DUMP_CFG_INPUT_FILE as input (ignores first 3 lines) and"
    echo "its expected format is csv: dump_idx,bus,slaveaddr,regaddr,page,size"
    echo "eg. 1,3,0x50 (bus 3, slave 0x50, addr default 0x00, read def. 256b)"
    echo "eg. 2,3,0x50,0,1 (bus 3, slave 0x50, addr explicit 0x00, explicit page
0x00, default 256b read size)"
    echo "eg. 5,3,0x50,,,64 (bus 3, slave 0x50, implicit reg addr 0x00, 
implicitly assume no page swap, read 64b size"
    echo "eg. 6,3,0x50,0x0f,0,128 (bus 3, slave 0x50, reg addr expl 0x0f, 
page swap expl 0x00, read 128b size)"
    echo "Usage: fpga_dump [-h] [-D] -p <file_path> -i <dump_id>"
    echo ""
    echo "Options:"
    echo "          -h  shows this help"
    echo "          -p  (required) path to put compressed dump to"
    echo "          -i  file dump id, default $ARG_DUMP_ID"
    echo "          -D  dbg script mocking i2c and csv input"
}

function dump_fpga()
{
    echo "Executing: $I2C_GET_REG_CMD"
    if $ARG_DBG_MODE ;then
        # in case of debug mode return test pattern to remove i2c dependency
        FPGA_REG_DUMP=$DBG_RUN_TEST_INPUT
        return 0
    fi

    FPGA_REG_DUMP=$($I2C_GET_REG_CMD 2>&1)
    DUMP_RC=$?

    if [ $DUMP_RC -ne 0 ]; then
        echo "FPGA registers dump failed"
        return 1
    fi

    return 0
}

function convert_and_save_as_bin()
{
    #convert 0x00 string representation to bash \x00 then dump to file
    local dump_bin_fmt=$(sed 's|0x|\\x|g; s| ||g' <<< $FPGA_REG_DUMP)
    echo -n -e "$dump_bin_fmt" > $TMP_DUMP_NAME_BIN
}


function initialize()
{
    if $ARG_DBG_MODE ;then
        # override and mock internals in dbg mode, create dummy input csv file
        # to remove its dependency
        TMP_DIR="/tmp/fpga_dump_dbg"
        DBG_RUN_TEST_INPUT="0x00 0x01 0x02 0x03 0x04 0x05"
        mkdir -p "$TMP_DIR"
        I2C_DUMP_CFG_INPUT_FILE="$TMP_DIR/in.csv"
        echo -n -e \
"#note: first 3 lines are ignored; last line needs to end with nl;
# purpose: used for fpga dump to configure dump source
#idx,bus,slaveaddr,regaddr,page,size
1,3,0x50,0,0
2,3,0x50,0,1
3,3,0x50,
4,3,0x50
5,3,0x50,,,64
6,3,0x50,0,0,128
6,3,0x50,0x0f,0,128
#7,3,0x50,0x00,0,32
8,3,0x50,0x01,0,16
" > $I2C_DUMP_CFG_INPUT_FILE
    fi

    F_NAME_TEMPLATE=$"obmcdump_"$ARG_DUMP_ID"_$EPOCHTIME"
    TMP_DIR_PATH="$TMP_DIR/$F_NAME_TEMPLATE"
    OUTPUT_ARCHIVE_PATH="$TMP_DIR/$F_NAME_TEMPLATE.tar.xz"

    mkdir -p $ARG_FPGA_DUMP_PATH
    if [ $? -ne 0 ]; then
        echo "Failed to create destination directory $ARG_FPGA_DUMP_PATH"
        exit 1
    fi
    echo "Created dest dir $ARG_FPGA_DUMP_PATH"

    mkdir -p $TMP_DIR_PATH
    if [ $? -ne 0 ]; then
        echo "Failed to create temp work directory $TMP_DIR_PATH"
        exit 1
    fi
    echo "Created tmp work dir $TMP_DIR_PATH"
}

function cleanup()
{
    # do not clean up in dbg mode to allow inspection of temp files
    if $ARG_DBG_MODE ;then
        return 0
    fi

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
    while IFS="," read -r c1_idx c2_bus c3_slaveaddr c4_regaddr \
                            c5_page c6_size c7_ignore
    do
        if [[ "$c1_idx" =~ "#" ]] ;then # skip commented out entries
            continue 
        fi

        I2C_DUMP_IDX=$c1_idx
        I2C_BUS_HMC=$c2_bus
        I2C_ADDR_SLAVE=$c3_slaveaddr
        I2C_ADDR_REG=$c4_regaddr
        I2C_ADDR_PAGE=$c5_page
        # echo "[$c1_idx] [$c2_bus] [$c3_slaveaddr] [$c4_regaddr] [$c5_page] \
        # [$c6_size] [$c7_ignore]"

        if [ -z "$I2C_DUMP_IDX" ] || [ -z "$I2C_BUS_HMC" ] || [ -z "$I2C_ADDR_SLAVE" ]; then
            break
        fi

        I2C_ADDR_REG="0x00"
        if [ ! -z "$c4_regaddr" ] ;then
            I2C_ADDR_REG=$c4_regaddr
            RCNT=$c6_size
        fi

        WCNT=1
        TMP_DUMP_NAME=$TMP_DIR_PATH/$I2C_DUMP_IDX\_$I2C_BUS_HMC\_$I2C_ADDR_SLAVE\_$I2C_ADDR_REG
        if [ ! -z "$c5_page" ] ;then
            WCNT=2
            TMP_DUMP_NAME=$TMP_DIR_PATH/$I2C_DUMP_IDX\_$I2C_BUS_HMC\_$I2C_ADDR_SLAVE\_$I2C_ADDR_REG\_$I2C_ADDR_PAGE
        fi
        TMP_DUMP_NAME_BIN=$TMP_DUMP_NAME.bin

        RCNT=256
        if [ ! -z "$c6_size" ] ;then
            RCNT=$c6_size
        fi

        I2C_GET_REG_CMD="i2ctransfer -y $I2C_BUS_HMC w$WCNT@$I2C_ADDR_SLAVE \
$I2C_ADDR_REG $I2C_ADDR_PAGE r$RCNT"
      
        #dump to temporary variable
        FPGA_REG_DUMP=""
        dump_fpga
        if [ $? -ne 0 ]; then
            echo "Dump $c1_idx failed (bus $c2_bus addr $c3_slaveaddr \
            page $c4_page)"
            echo "Error during dump (msg $FPGA_REG_DUMP) rc $DUMP_RC" > $TMP_DUMP_NAME_BIN
            continue
        fi
        
        #take tmp string dump as input and convert it to bin stream then save
        convert_and_save_as_bin
    done < <(tail -n +4 $I2C_DUMP_CFG_INPUT_FILE)

    # compress intermediate dir to archive
    tar -Jcf $OUTPUT_ARCHIVE_PATH -C $(dirname "$TMP_DIR_PATH") \
        $(basename "$TMP_DIR_PATH")

    if [ $? -ne 0 ]; then
        echo "Compression $OUTPUT_ARCHIVE_PATH failed"
        return 1
    fi

    # cp compressed archive to destination dir
    cp $OUTPUT_ARCHIVE_PATH $ARG_FPGA_DUMP_PATH
    if [ $? -ne 0 ]; then
        echo "Failed to copy $OUTPUT_ARCHIVE_PATH to $ARG_FPGA_DUMP_PATH"
        return 1
    fi

    return 0
}

while getopts ":hDp:i:" option; do
   case $option in
      h) # display help
         help
         exit;;

      D) # dbg mode
         ARG_DBG_MODE=true
         ;;

      p) # output file path
         ARG_FPGA_DUMP_PATH=$OPTARG
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

if [ ! "$ARG_FPGA_DUMP_PATH" ]; then
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
