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
BMC_EROT_MCTPEID="0"

# Firmware
checkout_firmware() {
## BMC/HMC
check="run_firmware_check_structure"
output="## HMC Firmware Attributes ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC-Version-01
run_checker get_hmc_fw_version_file
# HMC-HMC-Version-03
run_checker get_hmc_fw_build_type
# HMC-HMC_EROT-Version-01
run_checker get_hmc_erot_fw_version_pldm "$BMC_EROT_MCTPEID"
# HMC-HMC-IROT-02
run_checker get_bmc_jtag_bus_state
# HMC-HMC_EROT-PLDM_T5-05
run_checker get_hmc_erot_pldm_apsku_id "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-06
run_checker get_hmc_erot_pldm_ecsku_id "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-Key-04
run_checker get_hmc_erot_ec_key_revoke_state_vdm "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-Key-06
run_checker get_hmc_erot_ap_key_revoke_state_vdm "$BMC_EROT_MCTPEID"

} # checkout_firmware

# FPGA
checkout_fpga() {
## HW-Interface
check="run_hw_check_structure"
output="## FPGA Hardware Interface ##"
echo -e "$check\e[47G>>>Output>>>  $output"

# HMC-FPGA-GPIO-06
run_checker is_fpga_gpio_fpga_ready_set "FPGA0_READY_HMC-I"
run_checker is_fpga_gpio_fpga_ready_set "FPGA0_READY_HMC-I"
} # checkout_fpga

HMC_USB_IP="172.31.13.251"
BMC_FRU_BUS="10"
BMC_FRU_ADDR="0x50"
BMC_HMC_USB="hmcusb0"
BMC_EROT_MCTPEID="0"
BMC_SPI="mctp-spi0"
BMC_SPI_DBUS="xyz.openbmc_project.MCTP.Control.SPI0"
BMC_FW_ID="FW_BMC_0"
BMC_SPDM_ID="ERoT_BMC_0"
BMC_FW_SPDM_ID="FW_ERoT_BMC_0"

# BMC
checkout_bmc() {
## HW-Interface
check="run_hw_check_structure"
output="## BMC Hardware Interface ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-BMC-USB-04
run_checker is_hmc_usb_operational "$HMC_USB_IP"
# P2312-HW-Version-01
run_checker get_p2312_hw_product_name "$BMC_FRU_BUS" "$BMC_FRU_ADDR"
# HMC-BMC-USB-01
run_checker get_hmc_usb_operstate "$BMC_HMC_USB"
# HMC-BMC-USB-02
run_checker get_hmc_usb_ip "$BMC_HMC_USB"
# HMC-HMC_FLASH-SPI-01
run_checker get_hmc_flash_part_name_spi
# HMC-HMC_FLASH-SPI-02
run_checker get_hmc_flash_part_vendor_spi
## Transport-Protocol
check="run_hw_check_structure"
output="## BMC Transport Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC-Service-06
run_checker is_hmc_mctp_spi_ctrl_service_active "$BMC_SPI-ctrl.service"
# HMC-HMC-Service-07
run_checker is_hmc_mctp_spi_demux_service_active "$BMC_SPI-demux.service"
# HMC-HMC-DBUS-11
run_checker get_hmc_dbus_mctp_spi_tree_eids "$BMC_SPI_DBUS"
# HMC-HMC_EROT-DBUS-12
run_checker get_hmc_dbus_mctp_spi_spi_uuid "$BMC_EROT_MCTPEID" "$BMC_SPI_DBUS"
## Base-Protocol
check="run_hw_check_structure"
output="## BMC Base Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC_EROT-PLDM_T0-01
run_checker get_hmc_erot_pldm_tid "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T0-02
run_checker get_hmc_erot_pldm_pldmtypes "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T0-03
run_checker get_hmc_erot_pldm_t0_pldmversion "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T0-04
run_checker get_hmc_erot_pldm_t5_pldmversion "$BMC_EROT_MCTPEID"
## FW_Update-Protocol
check="run_hw_check_structure"
output="## BMC Firmware Update Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
# HMC-HMC-Service-08
run_checker is_hmc_pldmd_service_active
# HMC-HMC-Version-01
run_checker get_hmc_fw_version_file
# HMC-HMC-Version-02
run_checker get_hmc_fw_version_dbus "$BMC_FW_ID"
# HMC-HMC-Version-03
run_checker get_hmc_fw_build_type
# HMC-HMC_EROT-Version-01
run_checker get_hmc_erot_fw_version_pldm "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-Version-02
run_checker get_hmc_erot_fw_version_pldm_dbus "$BMC_FW_SPDM_ID"
# HMC-HMC_EROT-Version-03
run_checker get_hmc_erot_fw_build_type "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-Version-04
run_checker get_hmc_erot_fw_keyset "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-Version-06
run_checker get_hmc_erot_fw_boot_slot "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-Version-07
run_checker get_hmc_erot_fw_ec_identical "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-01
run_checker get_hmc_erot_pldm_version "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-02
run_checker get_hmc_erot_pldm_version_string "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-05
run_checker get_hmc_erot_pldm_apsku_id "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-PLDM_T5-06
run_checker get_hmc_erot_pldm_ecsku_id "$BMC_EROT_MCTPEID"
# HMC-HMC-DBUS-02
run_checker get_dbus_pldm_tree_ids
# HMC-HMC_EROT-DBUS-03
run_checker get_hmc_dbus_pldm_hmc_erot_uuid "$BMC_SPDM_ID"
# HMC-HMC_EROT-DBUS-05
run_checker get_hmc_dbus_pldm_hmc_erot_version "$BMC_FW_SPDM_ID"
## Telemetry-Protocol
check="run_hw_check_structure"
output="## HMC Telemetry Protocol ##"
echo -e "$check\e[47G>>>Output>>>  $output"
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
run_checker get_hmc_erot_spdm_version "$BMC_SPDM_ID"
# HMC-HMC_EROT-SPDM-02
run_checker get_hmc_erot_spdm_measurements_type "$BMC_SPDM_ID"
# HMC-HMC_EROT-SPDM-03
run_checker get_hmc_erot_spdm_hash_algorithms "$BMC_SPDM_ID"
# HMC-HMC_EROT-SPDM-04
run_checker get_hmc_erot_spdm_measurement_serial_number "$BMC_SPDM_ID"
# HMC-HMC_EROT-SPDM-05
run_checker get_hmc_erot_spdm_measurement_token_request "$BMC_SPDM_ID"
# HMC-HMC_EROT-SPDM-06
run_checker get_hmc_erot_spdm_certificate_count "$BMC_SPDM_ID"
# HMC-HMC_EROT-Key-04
run_checker get_hmc_erot_ec_key_revoke_state_vdm "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-Key-06
run_checker get_hmc_erot_ap_key_revoke_state_vdm "$BMC_EROT_MCTPEID"
# HMC-HMC_EROT-Security-01
run_checker get_hmc_erot_background_copy_progress_state_vdm "$BMC_EROT_MCTPEID"
} # checkout_hmc

# ... [add other run_checker calls here]

# Check if any arguments were provided
if [ $# -eq 0 ]; then
    # Run the default operations: check all components
    checkout_firmware
    checkout_bmc
    checkout_fpga
    checkout_gpu
else
    # Iterate over all provided arguments
    for arg in "$@"; do
        case $arg in
            bmc) checkout_bmc ;;
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
