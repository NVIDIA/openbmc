#!/bin/sh
set -e

CPLD_CONFIG_RO_DIR="/usr/share/nvidia-power-manager"
CPLD_CONFIG_RW_DIR="/etc/default/cpldmanager"
CPLD_ENV_DIR="/etc/cpldupdate"
CPLD_ENV_LINK="${CPLD_ENV_DIR}/cpldmanager.env"

PLDM_CONFIG_RO_DIR="/usr/share/pldm"
PLDM_CONFIG_RW_DIR="/etc/default/pldm"

# Create cpldmanager directory if it doesn't exist
if ! mkdir -p "${CPLD_CONFIG_RW_DIR}"; then
    echo "Error: Failed to create directory ${CPLD_CONFIG_RW_DIR}"
    exit 1
fi

# Create pldm directory if it doesn't exist
if ! mkdir -p "${PLDM_CONFIG_RW_DIR}"; then
    echo "Error: Failed to create directory ${PLDM_CONFIG_RW_DIR}"
    exit 1
fi

# BP CPLD i2c addresses are 0x40, 0x41 and 0x43
# We use 0x41 instead of 0x40 to avoid false positives 
# due to the starting offset 40 in i2cdetect results
check_bp_cpld() {
    if ! i2cdetect -y "$1" 0x41 0x41 | grep -q 41; then
        return 1
    fi
    return 0
}

copy_cpld_config() {
    local config_file="$1"
    local source="${CPLD_CONFIG_RO_DIR}/${config_file}"
    local target="${CPLD_CONFIG_RW_DIR}/cpld_config.json"

    if [ ! -f "${source}" ]; then
        echo "Error: Source file ${source} not found"
        return 1
    fi

    if ! cp -af "${source}" "${target}"; then
        echo "Error: Failed to copy ${source} to ${target}"
        return 1
    fi
    echo "Copied ${config_file} to ${target}"
}

create_cpld_env_link() {
    local env_file="$1"
    local source="${CPLD_ENV_DIR}/${env_file}"

    if [ ! -f "${source}" ]; then
        echo "Error: Source file ${source} not found"
        return 1
    fi

    if ! ln -sf "${source}" "${CPLD_ENV_LINK}"; then
        echo "Error: Failed to create symlink to ${env_file}"
        return 1
    fi
    echo "Created soft link to ${env_file}"
}

copy_pldm_config() {
    local config_file="$1"
    local source="${PLDM_CONFIG_RO_DIR}/${config_file}"
    local target="${PLDM_CONFIG_RW_DIR}/fw_update_config.json"

    if [ ! -f "${source}" ]; then
        echo "Error: Source file ${source} not found"
        return 1
    fi

    if ! cp -af "${source}" "${target}"; then
        echo "Error: Failed to copy ${source} to ${target}"
        return 1
    fi
    echo "Copied ${config_file} to ${target}"
}

# BP CPLDs locate on bus 17 and 29
detect_io_board() {
    if check_bp_cpld 17 || check_bp_cpld 29; then
        echo "CX8 IO board detected"
        copy_cpld_config "cpld_config_cx8.json"
        copy_pldm_config "fw_update_config_cx8.json"
        create_cpld_env_link "cpldmanager_cx8.env"

        # Hold SMA reset pin as we don't use it at the moment
        echo "Holding SMA reset pin"
        gpioset `gpiofind MCU_RST_N-O`=0
        gpioset `gpiofind SEC_MCU_RST_N-O`=0
    else
        echo "CX7 IO board detected"
        copy_cpld_config "cpld_config_cx7.json"
        copy_pldm_config "fw_update_config_cx7.json"
        create_cpld_env_link "cpldmanager_cx7.env"
    fi
}

detect_io_board
