#!/bin/bash

# Wrapper script to run various checks using the HMC checker

# Define the path to the checker script
checker="/usr/bin/hmc_checker.sh"
checker_timeout_second=15

# Ensure that the checker script exists and is executable
if [ ! -x "$checker" ]; then
    echo "Error: Checker script '$checker' not found or is not executable." >&2
    exit 1
fi

# Function to run a checker command with up to three additional arguments
run_checker() {
    local check=$(echo "$1" | tr -d "\n")
    local var="$2"
    local output

    # Check if the checker script is passed a valid command
    if [ -z "$check" ]; then
        echo "Error: No check command specified." >&2
        return 1
    fi

    # If $var is provided,
    # check if the $var is an array by assessing the first element existed.
    ## WIP if the provided var is an array, return
    [ -z "${var}" ] && [ -z "${var[0]+_}" ] && exit 1

    # Run the checker command and arguments with timeout predefined
    output=$(timeout "$checker_timeout_second" "$checker" "$@")

    # check if running into a timeout (124) or terminate (143) event
    [[ $? -eq 124 || $? -eq 143 ]] && output="execution timeout"

    output=$(echo "${output}" | tr -d "\0")
    # '\e[47G' an ANSI escape code, moving the cursor to the 47th col of the terminal
    echo -e "$check\e[47G>>>Output>>>  $output"
}

# Define GB200-NVL specific variables
HMC_EROT_MCTPEID="15"
FPGA_EROT_MCTPEID="13"
FPGA_BUS_NUM=("1" "2")
FPGA_REG_INT="0x0b"
FPGA_FWV_N_BYTES="1"
FPGA_FW_MJR_STR="0x04"
FPGA_SPDM_IDS=("HGX_ERoT_FPGA_0" "HGX_ERoT_FPGA_1")
CPU_SPDM_IDS=("HGX_ERoT_CPU_0" "HGX_ERoT_CPU_1")
FPGA_PLDM_EROT_IDS=("HGX_FW_ERoT_FPGA_0" "HGX_FW_ERoT_FPGA_0")
fpga_device_qty="2"
FPGA_EIDs=("13" "20")
BMC_USB_IP="172.31.13.241"
MCTP_USB_BUS="xyz.openbmc_project.MCTP.Control.USB"
HMC_FRU_BUS="3"
HMC_FRU_ADDR="0x57"

# Run various checks using the checker script

# HMC
checkout_hmc() {
## HW-Interface
check="run_hw_check_structure"
output="## HMC Hardware Interface ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC-Service-01
run_checker is_hmc_fpga_ready_service_active
# HMC-HMC-Service-02
run_checker is_hmc_fpga_ready_monitor_service_active
# HMC-BMC-USB-04
run_checker is_hmc_usb_operational "$BMC_USB_IP"
# P2312-HW-Version-01
run_checker get_p2312_hw_product_name "$HMC_FRU_BUS" "$HMC_FRU_ADDR"
# HMC-BMC-USB-01
run_checker get_hmc_usb_operstate
# HMC-BMC-USB-02
run_checker get_hmc_usb_ip
# HMC-HMC_FLASH-SPI-01
run_checker get_hmc_flash_part_name_spi
# HMC-HMC_FLASH-SPI-02
run_checker get_hmc_flash_part_vendor_spi
## Transport-Protocol
check="run_hw_check_structure"
output="## HMC Transport Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC-Service-04
run_checker is_hmc_mctp_usb_ctrl_service_active
# HMC-HMC-Service-05
run_checker is_hmc_mctp_usb_demux_service_active
# HMC-HMC-Service-06
run_checker is_hmc_mctp_spi_ctrl_service_active
# HMC-HMC-Service-07
run_checker is_hmc_mctp_spi_demux_service_active
# HMC-HMC-DBUS-01
run_checker get_hmc_dbus_mctp_vdm_tree_eids "$MCTP_USB_BUS"
# HMC-HMC-DBUS-11
run_checker get_hmc_dbus_mctp_spi_tree_eids
# HMC-HMC_EROT-DBUS-12
run_checker get_hmc_dbus_mctp_spi_spi_uuid
## Base-Protocol
check="run_hw_check_structure"
output="## HMC Base Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC_EROT-PLDM_T0-01
run_checker get_hmc_erot_pldm_tid "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T0-02
run_checker get_hmc_erot_pldm_pldmtypes "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T0-03
run_checker get_hmc_erot_pldm_t0_pldmversion "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T0-04
run_checker get_hmc_erot_pldm_t5_pldmversion "$HMC_EROT_MCTPEID"
## FW_Update-Protocol
check="run_hw_check_structure"
output="## HMC Firmware Update Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC-Service-08
run_checker is_hmc_pldmd_service_active
# HMC-HMC-Version-01
run_checker get_hmc_fw_version_file
# HMC-HMC-Version-02
run_checker get_hmc_fw_version_dbus
# HMC-HMC-Version-03
run_checker get_hmc_fw_build_type
# HMC-HMC_EROT-Version-01
run_checker get_hmc_erot_fw_version_pldm "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-Version-02
run_checker get_hmc_erot_fw_version_pldm_dbus
# HMC-HMC_EROT-Version-03
run_checker get_hmc_erot_fw_build_type "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-Version-04
run_checker get_hmc_erot_fw_keyset "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-Version-06
run_checker get_hmc_erot_fw_boot_slot "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-Version-07
run_checker get_hmc_erot_fw_ec_identical "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-01
run_checker get_hmc_erot_pldm_version
# HMC-HMC_EROT-PLDM_T5-02
run_checker get_hmc_erot_pldm_version_string
# HMC-HMC_EROT-PLDM_T5-05
run_checker get_hmc_erot_pldm_apsku_id "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-06
run_checker get_hmc_erot_pldm_ecsku_id "$HMC_EROT_MCTPEID"
# HMC-HMC-DBUS-02
run_checker get_dbus_pldm_tree_ids
# HMC-HMC_EROT-DBUS-03
run_checker get_hmc_dbus_pldm_hmc_erot_uuid
# HMC-HMC_EROT-DBUS-05
run_checker get_hmc_dbus_pldm_hmc_erot_version
## Telemetry-Protocol
check="run_hw_check_structure"
output="## HMC Telemetry Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC-Service-03
run_checker is_hmc_gpu_manager_service_inactive
# HMC-HMC-Service-11
run_checker is_hmc_nsmd_service_active
# HMC-HMC-PLDM_T2-01
run_checker is_hmc_pldm_t2_sensor_polling_enabled
## Security-Protocol
check="run_hw_check_structure"
output="## HMC Security Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC-Service-09
run_checker is_hmc_debugtoken_erase_service_active
# HMC-HMC-Service-10
run_checker is_hmc_debugtoken_install_service_active
# HMC-HMC-IROT-03
run_checker is_hmc_irot_otp_secure_boot_ignore_hw_strap_configured
# HMC-HMC-IROT-01
run_checker get_hmc_irot_secure_boot_status
# HMC-HMC-DBUS-10
run_checker get_dbus_spdm_tree_ids
# HMC-HMC_EROT-SPDM-01
run_checker get_hmc_erot_spdm_version
# HMC-HMC_EROT-SPDM-02
run_checker get_hmc_erot_spdm_measurements_type
# HMC-HMC_EROT-SPDM-03
run_checker get_hmc_erot_spdm_hash_algorithms
# HMC-HMC_EROT-SPDM-04
run_checker get_hmc_erot_spdm_measurement_serial_number
# HMC-HMC_EROT-SPDM-05
run_checker get_hmc_erot_spdm_measurement_token_request
# HMC-HMC_EROT-SPDM-06
run_checker get_hmc_erot_spdm_certificate_count
# HMC-HMC_EROT-Key-04
run_checker get_hmc_erot_ec_key_revoke_state_vdm "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-Key-06
run_checker get_hmc_erot_ap_key_revoke_state_vdm "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-Security-01
run_checker get_hmc_erot_background_copy_progress_state_vdm "$HMC_EROT_MCTPEID"
} # checkout_hmc

# FPGA
checkout_fpga() {
## HW-Interface
check="run_hw_check_structure"
output="## FPGA Hardware Interface ##"
echo -e "$check\e[47G>>>Output>>>  $output"

# HMC-FPGA-GPIO-06
run_checker is_fpga_gpio_fpga_ready_set "FPGA0_READY-I"
run_checker is_fpga_gpio_fpga_ready_set "FPGA1_READY-I"

# Iterate over both FPGAs
for (( i=0; i<$fpga_device_qty; i++ )); do

## Transport-Protocol
check="run_hw_check_structure"
output="## FPGA$((i+1)) Transport Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"


# HMC-FPGA-MCTP_VDM-01
run_checker is_fpga_vdm_operational "${FPGA_EIDs[$i]}"
# HMC-FPGA-MCTP_VDM-02
run_checker get_hmc_mctp_eids_tree "$MCTP_USB_BUS"
# HMC-FPGA_EROT-Key-04
run_checker get_fpga_erot_ec_key_revoke_state_vdm "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-Key-06
run_checker get_fpga_erot_ap_key_revoke_state_vdm "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-Security-01
run_checker get_fpga_erot_background_copy_progress_state_vdm "${FPGA_EIDs[$i]}"

# Base-Protocol
check="run_hw_check_structure"
output="## FPGA$((i+1)) Base Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"

# HMC-FPGA-NSM_T0-02
run_checker is_fpga_mctp_nsmtool_ping_operational
# HMC-FPGA_EROT-PLDM_T0-01
run_checker get_fpga_erot_pldm_tid "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-PLDM_T0-02
run_checker get_fpga_erot_pldm_pldmtypes "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-PLDM_T0-03
run_checker get_fpga_erot_pldm_t0_pldmversion "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-PLDM_T0-04
run_checker get_fpga_erot_pldm_t5_pldmversion "${FPGA_EIDs[$i]}"
# HMC-FPGA-NSM_T0-04
run_checker get_fpga_mctp_nsmtool_supported_message_types
## FW_Update-Protocol
check="run_hw_check_structure"
output="## FPGA$((i+1)) Firmware Update Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-FPGA-Version-01
run_checker get_fpga_fw_version_regtable "${FPGA_BUS_NUM[$i]}" "$FPGA_REG_INT" "$FPGA_FWV_N_BYTES" "$FPGA_FW_MJR_STR"
# HMC-FPGA_EROT-Version-01
run_checker get_fpga_erot_fw_version_pldm "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-Version-02
run_checker get_fpga_erot_fw_version_pldm_dbus "${FPGA_PLDM_EROT_IDS[$i]}"
# HMC-FPGA_EROT-Version-03
run_checker get_fpga_erot_fw_build_type "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-Version-04
run_checker get_fpga_erot_fw_keyset "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-Version-06
run_checker get_fpga_erot_fw_boot_slot "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-Version-07
run_checker get_fpga_erot_fw_ec_identical "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-PLDM_T5-01
run_checker get_fpga_erot_pldm_version "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-PLDM_T5-02
run_checker get_fpga_erot_pldm_version_string "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-DBUS-04
run_checker get_hmc_dbus_pldm_fpga_erot_uuid "${FPGA_PLDM_EROT_IDS[$i]}"
# HMC-FPGA_EROT-DBUS-06
run_checker get_hmc_dbus_pldm_fpga_erot_version "${FPGA_PLDM_EROT_IDS[$i]}"

# Security-Protocol
check="run_hw_check_structure"
output="## FPGA$((i+1)) Security Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-FPGA_EROT-SPDM-01
run_checker get_fpga_erot_spdm_version "${FPGA_SPDM_ID[$i]}"
# HMC-FPGA_EROT-SPDM-02
run_checker get_fpga_erot_spdm_measurements_type "${FPGA_SPDM_ID[$i]}"
# HMC-FPGA_EROT-SPDM-03
run_checker get_fpga_erot_spdm_hash_algorithms "${FPGA_SPDM_ID[$i]}"
# HMC-FPGA_EROT-SPDM-04
run_checker get_fpga_erot_spdm_measurement_serial_number "${FPGA_SPDM_ID[$i]}"
# HMC-FPGA_EROT-SPDM-05
run_checker get_fpga_erot_spdm_measurement_token_request "${FPGA_SPDM_ID[$i]}"
# HMC-FPGA_EROT-SPDM-06
run_checker get_fpga_erot_spdm_certificate_count "${FPGA_SPDM_ID[$i]}"
done #for loop
} # checkout_fpga

# GPU
checkout_gpu() {
local gpu_mctp_eids=("18" "19" "25" "26")
local gpu_sw_ids=("HGX_FW_GPU_0" "HGX_FW_GPU_1" "HGX_FW_GPU_2" "HGX_FW_GPU_3")

local device_qty=4

# Loop through all devices
for (( i=0; i<$device_qty; i++ )); do
check="run_device_check_structure"
output="# GPU Device $((i+1)) #"
echo -e "$check\e[47G>>>Output>>>  $output"

## HW-Interface
## Transport-Protocol
check="run_hw_check_structure"
output="## GPU Transport Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"

# HMC-GPU_IROT-DBUS-07
run_checker get_dbus_pldm_gpu_irot_version ${gpu_sw_ids[$i]}
## Telemetry-Protocol
check="run_hw_check_structure"
output="## GPU Telemetry Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-GPU-NSM_T2-01
run_checker get_gpu_mctp_nsmtool_t2_avil_simple_data_sources ${gpu_mctp_eids[$i]}
# HMC-GPU-NSM_T2-02
run_checker get_gpu_mctp_nsmtool_t2_avil_indexed_data_sources ${gpu_mctp_eids[$i]}
# HMC-GPU-NSM_T2-03
run_checker get_gpu_mctp_nsmtool_t2_avil_bulk_data_sources ${gpu_mctp_eids[$i]}
## Security-Protocol
done # for loop
} # checkout_gpu

# CPU
checkout_cpu() {
local cpu_mctp_eids=("16" "23")
local cpu_sw_ids=("HGX_FW_CPU_0" "HGX_FW_CPU_1")

local device_qty=2

# Loop through all devices
for (( i=0; i<$device_qty; i++ )); do
check="run_device_check_structure"
output="# CPU Device $((i+1)) #"
echo -e "$check\e[47G>>>Output>>>  $output"

## Transport-Protocol
check="run_hw_check_structure"
output="## CPU Transport Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-CPU_EROT-Key-04
run_checker get_cpu_erot_ec_key_revoke_state_vdm ${cpu_mctp_eids[$i]}
# HMC-CPU_EROT-Key-06
run_checker get_cpu_erot_ap_key_revoke_state_vdm ${cpu_mctp_eids[$i]}
# HMC-CPU_EROT-Security-01
run_checker get_cpu_erot_background_copy_progress_state_vdm ${cpu_mctp_eids[$i]}
done # for loop
} # checkout_gpu



# Firmware
checkout_firmware() {
## HMC
check="run_firmware_check_structure"
output="## HMC Firmware Attributes ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC-Version-01
run_checker get_hmc_fw_version_file
# HMC-HMC-Version-03
run_checker get_hmc_fw_build_type
# HMC-HMC_EROT-Version-01
run_checker get_hmc_erot_fw_version_pldm "$HMC_EROT_MCTPEID"
# HMC-HMC-IROT-02
run_checker is_hmc_irot_otp_secure_boot_enable_configured
# HMC-HMC_EROT-PLDM_T5-05
run_checker get_hmc_erot_pldm_apsku_id "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-06
run_checker get_hmc_erot_pldm_ecsku_id "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-07
run_checker get_hmc_erot_pldm_glacier_id "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-08
run_checker get_hmc_erot_pldm_pci_vendor_id "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-09
run_checker get_hmc_erot_pldm_pci_device_id "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-10
run_checker get_hmc_erot_pldm_pci_subsys_vendor_id "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-11
run_checker get_hmc_erot_pldm_pci_subsys_id "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-Key-04
run_checker get_hmc_erot_ec_key_revoke_state_vdm "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-Key-06
run_checker get_hmc_erot_ap_key_revoke_state_vdm "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-Version-04
run_checker get_hmc_erot_fw_keyset "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-Version-05
run_checker get_hmc_erot_fw_chiprev "$HMC_EROT_MCTPEID"
# HMC-HMC-IROT-02
run_checker is_hmc_irot_otp_secure_boot_enable_configured
# P2312-HW-Version-02
run_checker get_p2312_hw_serial_number "3" "0x57"
# HMC-HMC_EROT-Version-03
run_checker get_hmc_erot_fw_build_type "$HMC_EROT_MCTPEID"
# HMC-HMC_EROT-SPDM-06
run_checker get_hmc_erot_spdm_certificate_count
# HMC-HMC_EROT-Security-01
run_checker get_hmc_erot_background_copy_progress_state_vdm "$HMC_EROT_MCTPEID"


## FPGA
local fpga_mctp_eids=("13" "20")
local device_qty=2
# Loop through all devices
for (( i=0; i<$device_qty; i++ )); do
check="run_firmware_check_structure"
output="## FPGA$((i+1)) Firmware Attributes ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-FPGA-Version-01
run_checker get_fpga_fw_version_regtable "${FPGA_BUS_NUM[$i]}" "$FPGA_REG_INT" "$FPGA_FWV_N_BYTES" "$FPGA_FW_MJR_STR"
# HMC-FPGA_EROT-Version-01
run_checker get_fpga_erot_fw_version_pldm "${fpga_mctp_eids[$i]}"
# HMC-FPGA_EROT-PLDM_T5-05
run_checker get_fpga_erot_pldm_apsku_id "${fpga_mctp_eids[$i]}"
# HMC-FPGA_EROT-PLDM_T5-06
run_checker get_fpga_erot_pldm_ecsku_id "${fpga_mctp_eids[$i]}"
# HMC-FPGA_EROT-PLDM_T5-07
run_checker get_fpga_erot_pldm_glacier_id "${fpga_mctp_eids[$i]}"
# HMC-FPGA_EROT-PLDM_T5-08
run_checker get_fpga_erot_pldm_pci_vendor_id "${fpga_mctp_eids[$i]}"
# HMC-FPGA_EROT-PLDM_T5-09
run_checker get_fpga_erot_pldm_pci_device_id "${fpga_mctp_eids[$i]}"
# HMC-FPGA_EROT-PLDM_T5-10
run_checker get_fpga_erot_pldm_pci_subsys_vendor_id "${fpga_mctp_eids[$i]}"
# HMC-FPGA_EROT-PLDM_T5-11
run_checker get_fpga_erot_pldm_pci_subsys_id "${fpga_mctp_eids[$i]}"
# HMC-FPGA_EROT-Key-04
run_checker get_fpga_erot_ec_key_revoke_state_vdm "${FPGA_EIDs[$i]}"
# HMC-FPGA_EROT-Key-06
run_checker get_fpga_erot_ap_key_revoke_state_vdm "${FPGA_EIDs[$i]}"
# # HMC-FPGA_EROT-Version-04
run_checker get_fpga_erot_fw_keyset "${fpga_mctp_eids[$i]}"
# HMC-FPGA_EROT-Version-05
run_checker get_fpga_erot_fw_chiprev "${fpga_mctp_eids[$i]}"
# # HMC-FPGA_EROT-Version-03
run_checker get_fpga_erot_fw_build_type "${fpga_mctp_eids[$i]}"
# HMC-FPGA_EROT-SPDM-06
run_checker get_fpga_erot_spdm_certificate_count "${FPGA_SPDM_ID[$i]}"
# HMC-FPGA_EROT-Security-01
run_checker get_fpga_erot_background_copy_progress_state_vdm "${FPGA_EIDs[$i]}"
done # for loop

## GPU
local gpu_mctp_eids=("18" "19" "25" "26")
local gpu_sw_ids=("HGX_FW_GPU_0" "HGX_FW_GPU_1" "HGX_FW_GPU_2" "HGX_FW_GPU_3")
local device_qty=4
# Loop through all devices
for (( i=0; i<$device_qty; i++ )); do
check="run_device_check_structure"
output="# GPU Device $((i+1)) #"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-GPU_IROT-Version-01
run_checker get_gpu_irot_fw_version_pldm "${gpu_mctp_eids[$i]}"
# HMC-GPU_IROT-Version-02
run_checker get_gpu_irot_fw_version_pldm_dbus ${gpu_sw_ids[$i]}
# HMC-GPU_IROT-PLDM_T5-05
run_checker get_gpu_irot_pldm_apsku_id "${gpu_mctp_eids[$i]}"
# HMC-GPU_IROT-PLDM_T5-08
run_checker get_gpu_irot_pldm_pci_vendor_id "${gpu_mctp_eids[$i]}"
# HMC-GPU_IROT-PLDM_T5-09
run_checker get_gpu_irot_pldm_pci_device_id "${gpu_mctp_eids[$i]}"
# HMC-GPU_IROT-PLDM_T5-10
run_checker get_gpu_irot_pldm_pci_subsys_vendor_id "${gpu_mctp_eids[$i]}"
# HMC-GPU_IROT-PLDM_T5-11
run_checker get_gpu_irot_pldm_pci_subsys_id "${gpu_mctp_eids[$i]}"
done # for loop


## CPU
local cpu_mctp_eids=("16" "23")
local device_qty=2
# Loop through all devices
for (( i=0; i<$device_qty; i++ )); do
check="run_device_check_structure"
output="# CPU Device $((i+1)) #"
echo -e "$check\e[47G>>>Output>>>  $output"

## Transport-Protocol
check="run_hw_check_structure"
output="## CPU Transport Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-CPU_EROT-Version-01
run_checker get_cpu_erot_fw_version_pldm "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-Version-03
run_checker get_cpu_erot_fw_build_type "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-Version-04
run_checker get_cpu_erot_fw_keyset "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-Version-05
run_checker get_cpu_erot_fw_chiprev "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-PLDM_T5-05
run_checker get_cpu_erot_pldm_apsku_id "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-PLDM_T5-06
run_checker get_cpu_erot_pldm_ecsku_id "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-PLDM_T5-07
run_checker get_cpu_erot_pldm_glacier_id "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-PLDM_T5-08
run_checker get_cpu_erot_pldm_pci_vendor_id "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-PLDM_T5-09
run_checker get_cpu_erot_pldm_pci_device_id "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-PLDM_T5-10
run_checker get_cpu_erot_pldm_pci_subsys_vendor_id "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-PLDM_T5-11
run_checker get_cpu_erot_pldm_pci_subsys_id "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-Key-04
run_checker get_cpu_erot_ec_key_revoke_state_vdm "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-Key-06
run_checker get_cpu_erot_ap_key_revoke_state_vdm "${cpu_mctp_eids[$i]}"
# HMC-CPU_EROT-SPDM-06
run_checker get_cpu_erot_spdm_certificate_count "${CPU_SPDM_IDS[$i]}"
# HMC-CPU_EROT-Security-01
run_checker get_cpu_erot_background_copy_progress_state_vdm "${cpu_mctp_eids[$i]}"

done # for loop

} # checkout_firmware

# ... [add other run_checker calls here]

# Check if any arguments were provided
if [ $# -eq 0 ]; then
    # Run the default operations: check all components
    checkout_firmware
    checkout_hmc
    checkout_fpga
    checkout_gpu
else
    # Iterate over all provided arguments
    for arg in "$@"; do
        case $arg in
            hmc) checkout_hmc ;;
            fpga) checkout_fpga ;;
            gpu) checkout_gpu ;;
            firmware) checkout_firmware;;
            *) echo "Unknown argument: $arg. Skipping." ;;
        esac
    done
fi

# Check exit status of the last run_checker call
if [ $? -ne 0 ]; then
    echo "Error: Last checker command encountered an issue." >&2
    exit 1
fi

echo "All checks completed successfully."
