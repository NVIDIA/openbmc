#!/usr/bin/env sh

OTP_BASE_DIR="${OTP_BASE_DIR:-/var/lib/otp}"
OTP_HW_ENABLED="${OTP_HW_ENABLED:-1}"
OTP_STATUS_FILE_DIR="${OTP_STATUS_FILE_DIR:-/var/lib/otp-provisioning}"

OTP_CONF0123_EMPTY=00000000000000000000000000000000
OTP_CONF7_EMPTY=00000000
OTP_CONF7_PROGRAMMED=00008000
OTP_CONF1C1D_EMPTY=0000000000000000
OTP_CONF1C1D_PROGRAMMED=00008002a0000000

remove_otp_files() {
    if [ -d "${OTP_BASE_DIR}" ]; then
        xargs rm -f < <(find "${OTP_BASE_DIR}" -maxdepth 3 -type f)
    fi
}

if [ -f /usr/bin/otp-bus.sh ]; then
    source /usr/bin/otp-bus.sh
else
    echo "/usr/bin/otp-bus.sh not found. setting i2c bus to 0"
    OTP_BUS=0
fi

echo "Checking OTP provisioning status..."
if [ x"${OTP_HW_ENABLED}" = x"1" ]; then
    # 8/10/2022 - OTP is not supported in qemu; otp read / prog call
    # attempts in qemu cause kernel panic and reboot
    # QEMU detection is based on checking number of devices present
    # on I2C 0 bus
    # 1 device (2 address characters) indicates a qemu machine
    # sleep is added to account for th boot-up time of the bus and devices
    I2C_0_DEVICES=$(i2cdetect -y $OTP_BUS | \
        cut -c5- | sed 1d | tr -dc '[:alnum:]' | wc -c)
    if [ "${I2C_0_DEVICES}" -le "2" ]; then
        sleep 20
        I2C_0_DEVICES=$(i2cdetect -y $OTP_BUS | \
        cut -c5- | sed 1d | tr -dc '[:alnum:]' | wc -c)
        echo "I2C-0 bus devices found (x2):" ${I2C_0_DEVICES}
        if [ "${I2C_0_DEVICES}" -le "2" ]; then
            echo "QEMU detected"
            printf "0\nOTPDISABLED\n" > "${OTP_STATUS_FILE_DIR}/status"
            exit
        fi
    fi

    OTP_CONF0123=$(otp read conf 0 4 | cut -d ":" -f 2 | xargs printf "%08x")
    OTP_CONF7=$(otp read conf 7 1 | cut -d ":" -f 2 | xargs printf "%08x")
    OTP_CONF1C1D=$(otp read conf 1c 2 | cut -d ":" -f 2 | xargs printf "%08x")
    OTP_DATA=$(otp read data 0 800 | \
        cut -d ":" -f 2 | tr -d ' \n' | \
        sed -e 's/00000000//g' -e 's/00000001//g' -e 's/FFFFFFFF//g' -e 's/FFFFFFFE//g')

    CONF_TYPE=""
    if  [ -z "${OTP_DATA}" ] &&  \
        [ "${OTP_CONF7}" = "${OTP_CONF7_EMPTY}" ] && \
        [ "${OTP_CONF1C1D}" = "${OTP_CONF1C1D_EMPTY}" ] && \
        [ "${OTP_CONF0123}" = "${OTP_CONF0123_EMPTY}" ]; then
        echo "OTP is not provisioned"
        printf "0\nEMPTY\n" > "${OTP_STATUS_FILE_DIR}/status"
        CONF_TYPE="empty"
    fi
    if  [ ! -z "${OTP_DATA}" ] && \
        [ "${OTP_CONF7}" = "${OTP_CONF7_PROGRAMMED}" ] && \
        [ "${OTP_CONF1C1D}" = "${OTP_CONF1C1D_PROGRAMMED}" ]; then
        for CONF in ${OTP_CONFIGURATIONS}; do
            CONF_NAME=$(echo "${CONF}" | cut -d ";" -f 1)
            CONF_VAL=$(echo "${CONF}" | cut -d ";" -f 2)
            if [ "${OTP_CONF0123}" = "${CONF_VAL}" ]; then
                echo "${CONF_NAME} configuration found"
                printf "1\n${CONF_NAME}\n" > "${OTP_STATUS_FILE_DIR}/status"
                remove_otp_files
                CONF_TYPE=$(echo ${CONF_NAME} | tr [:upper:] [:lower:])
                break
            fi
        done
    fi
    if [ -z "${CONF_TYPE}" ]; then
        echo "Erroneous OTP contents found"
        printf "0\nERROR\n" > "${OTP_STATUS_FILE_DIR}/status"
        CONF_TYPE="error"
    fi

    if [ "${OTP_DUMP}" = "1" ]; then
        LAST_DUMP=$(find ${OTP_STATUS_FILE_DIR} -mindepth 1 -maxdepth 1 -name "dump_*" -type d | sort | tail -n 1 | cut -d "_" -f 2)
        if [ -z ${LAST_DUMP} ]; then
            LAST_DUMP=00
        fi
        NEW_DUMP=$(printf "%02d" $((${LAST_DUMP} + 1)))
        echo "Dumping OTP contents in ${OTP_STATUS_FILE_DIR}/dump_${NEW_DUMP} directory"
        mkdir -p ${OTP_STATUS_FILE_DIR}/dump_${NEW_DUMP}
        otp info conf > ${OTP_STATUS_FILE_DIR}/dump_${NEW_DUMP}/otp_info_conf_${CONF_TYPE}
        otp info scu > ${OTP_STATUS_FILE_DIR}/dump_${NEW_DUMP}/otp_info_scu_${CONF_TYPE}
        otp info strap > ${OTP_STATUS_FILE_DIR}/dump_${NEW_DUMP}/otp_info_strap_${CONF_TYPE}
        otp read conf 0 20 > ${OTP_STATUS_FILE_DIR}/dump_${NEW_DUMP}/otp_read_conf_${CONF_TYPE}
        otp read data 0 800 > ${OTP_STATUS_FILE_DIR}/dump_${NEW_DUMP}/otp_read_data_${CONF_TYPE}
    fi
else
    echo "OTP HW disabled"
    printf "0\nOTPDISABLED\n" > "${OTP_STATUS_FILE_DIR}/status"
fi

