#!/bin/bash

MCTP_VDM_UTIL_TIMEOUT=3

get_erot_uuid() {
    local BMC_OBJS=$(busctl call xyz.openbmc_project.ObjectMapper /xyz/openbmc_project/object_mapper xyz.openbmc_project.ObjectMapper GetSubTreePaths sias "/" 0 1 xyz.openbmc_project.Inventory.Item.BMC | cut -d" " -f3- | tr -d '"')
    for BMC in ${BMC_OBJS}; do
        ROT_OBJS=$(busctl call xyz.openbmc_project.ObjectMapper /xyz/openbmc_project/object_mapper xyz.openbmc_project.ObjectMapper GetAssociatedSubTreePaths ooias ${BMC}/associated_ROT "/" 0 0 | cut -d" " -f3- | tr -d '"')
        for ROT in ${ROT_OBJS}; do
            SERVICE=$(busctl call xyz.openbmc_project.ObjectMapper /xyz/openbmc_project/object_mapper xyz.openbmc_project.ObjectMapper GetObject sas ${ROT} 1 xyz.openbmc_project.Common.UUID | cut -d" " -f3 | tr -d '"')
            if [ ! -z "${SERVICE}" ]; then
                UUID=$(busctl get-property ${SERVICE} ${ROT} xyz.openbmc_project.Common.UUID UUID | cut -d" " -f2 | tr -d '"')
                if [ ! -z "${UUID}" ]; then
                    echo "${UUID}"
                    return 0
                fi
            fi
        done
    done
    return 1
}

get_erot_eid() {
    local MCTP_EPS=$(busctl call xyz.openbmc_project.ObjectMapper /xyz/openbmc_project/object_mapper xyz.openbmc_project.ObjectMapper GetSubTreePaths sias "/" 0 1 xyz.openbmc_project.MCTP.Endpoint | cut -d" " -f3- | tr -d '"')
    for EP in ${MCTP_EPS}; do
        SERVICE=$(busctl call xyz.openbmc_project.ObjectMapper /xyz/openbmc_project/object_mapper xyz.openbmc_project.ObjectMapper GetObject sas ${EP} 1 xyz.openbmc_project.Common.UUID | cut -d" " -f3 | tr -d '"')
        if [ ! -z "${SERVICE}" ]; then
            UUID=$(busctl get-property ${SERVICE} ${EP} xyz.openbmc_project.Common.UUID UUID | cut -d" " -f2 | tr -d '"')
            if [ ! -z "${UUID}" ] && [ "${UUID}" = "${1}" ]; then
                EID=$(busctl get-property ${SERVICE} ${EP} xyz.openbmc_project.MCTP.Endpoint EID | cut -d" " -f2)
                echo "${EID}"
                return 0
            fi
        fi
    done
    return 1
}

check_token_status() {
    local TOKEN_STATUS=""
    TOKEN_STATUS_RESP=$(mctp-vdm-util -t ${1} -c debug_token_query -o ${MCTP_VDM_UTIL_TIMEOUT} | grep RX | cut -d":" -f2)
    echo "Token status received from EID ${1}:${TOKEN_STATUS_RESP}" | systemd-cat -t "dropbear" -p "notice"
    TOKEN_STATUS_RC=$(cut -d" " -f10 <<< ${TOKEN_STATUS_RESP})
    if [ "${TOKEN_STATUS_RC}" = "00" ]; then
        TOKEN_STATUS=$(cut -d" " -f11 <<< ${TOKEN_STATUS_RESP})
    else
        echo "MCTP VDM token status query return code: ${TOKEN_STATUS_RC}" >&2
        return 1
    fi
    if [ "${TOKEN_STATUS}" = "00" ]; then
        echo "Debug token not installed" >&2
        return 1
    elif [ "${TOKEN_STATUS}" = "01" ]; then
        echo "Debug token installed" >&2
        return 0
    else
        echo "MCTP VDM token status query invalid token status value: ${TOKEN_STATUS}" >&2
        return 1
    fi
    echo "Unhandled condition" >&2
    return 1
}

disallow_login() {
    echo "login not permitted" >&2
    exit 1
}

allow_login() {
    echo "login permitted" >&2
    exit 0
}

main() {
    BMC_EROT_UUID=$(get_erot_uuid)
    if [ "$?" != "0" ] || [ -z "${BMC_EROT_UUID}" ]; then
        disallow_login
    fi
    BMC_EROT_EID=$(get_erot_eid "${BMC_EROT_UUID}")
    if [ "$?" != "0" ] || [ -z "${BMC_EROT_EID}" ]; then
        disallow_login
    fi
    check_token_status ${BMC_EROT_EID}
    if [ "$?" = "0" ]; then
        allow_login
    fi
    disallow_login
}

main
