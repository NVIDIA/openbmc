#!/bin/bash

export LOG_FILE="/tmp/hmc_checker.log"
# Function to redirect and log stdout and stderr
# Arguments:
#   n/a
# Return:
#   the passed command's stdout
_log_() {
    # Ensure LOG_FILE variable is defined
    if [[ -z "$LOG_FILE" ]]; then
        echo "Error: LOG_FILE is not defined."
        return -1
    fi

    # Check if the log file does not exist and create it
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    fi

    # Log the function runtime date and the caller's function name
    echo "### $(date '+HMC UTC Time: %Y-%m%d-%H:%M:%S') - Called by: ${FUNCNAME[1]}" >> "$LOG_FILE"

    # Log the passed command and arguments
    echo "command: " >> "$LOG_FILE"
    echo "$@" >> "$LOG_FILE"

    # log command stdout and stderr
    echo "stdout or stderr: " >> "$LOG_FILE"

    # Execute the command, log stdout and stderr
    # We append both stdout and stderr to the log file
    if [ "$1" = "mctp-pcie-ctrl" ]; then
        # The 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
        # The pipe to 'tee' allows both stdout and stderr to be piped through
        "$@" 2>&1 | tee -a "$LOG_FILE"
    elif [[ "$1" = "nsmtool" &&  ("$2" = "raw") ]]; then
        # The 'nsmtool raw' use phoshpor-logging/lg2.
        # The command stdout of TTY cannot be redirected to a file nor grep.
        # The journal log records the command output, so grep from the log.
        nsmtool_pid=$("$@" >/dev/null 2>&1 & echo $!) && sleep 5; journalctl _PID=$nsmtool_pid | tee -a "$LOG_FILE"
    elif [[ "$1" = "pldmtool" &&  ("$2" = "raw") ]]; then
        # The 'pldmtool raw' use phoshpor-logging/lg2.
        # The command stdout of TTY cannot be redirected to a file nor grep.
        # The journal log records the command output, so grep from the log.
        pldmtool_pid=$("$@" >/dev/null 2>&1 & echo $!) && sleep 5; journalctl _PID=$pldmtool_pid | tee -a "$LOG_FILE"
    else
        # The pipe to 'tee' allows only stdout to be piped through
        "$@" 2> >(tee -a "$LOG_FILE" >/dev/null) | tee -a "$LOG_FILE"
    fi
}

__log_() { "$@" 2>/dev/null; }


# Component-Level Category: HMC #
## HMC: Hardware Interface

# HMC-BMC-USB-01
# Function to get USB operate state
# Arguments:
#   $1: USB interface
# Returns:
#   valid state "up"
get_hmc_usb_operstate() {
local usb_interface="$1"
# default usb0 to usb interface
usb=${usb_interface:-'usb0'} && op_path="/sys/class/net/"$usb"/operstate" && [ -f "$op_path" ] && _log_ cat "$op_path"
}

# HMC-BMC-USB-02
# Function to get USB interface IP
# Arguments:
#   $1: USB interface
# Returns:
#   valid IP "192.168.31.1"
get_hmc_usb_ip() {
local usb_interface="$1"
# default usb0 to usb interface
usb=${usb_interface:-'usb0'} && _log_ ifconfig "$usb" | grep -o 'inet addr:[^ ]*' | sed 's/inet addr://'
}

# HMC-BMC-USB-04
# Function to verify if USB NIC is operational
# Arguments:
#   $1: remote IP
#   $2: count, the number of ping packets to send
# Returns:
#   valid "yes", "no" otherwise
is_hmc_usb_operational() {
local bmc_ip="$1"
local count="$2"

ip=${remote_ip:-'192.168.31.2'} && count=${count:-1} && if _log_ ping -c "$count" "$ip" >/dev/null 2>&1; then echo "yes"; else echo "no"; fi
}

# Baseboard-HW-Version-01
# Function to get Product Name from Baseboard FRU through FPGA
# Arguments:
#   $1: HMC I2C bus where the Basebaord FRU resides
#   $2: Basebaord FRU I2C address
# Return:
#   valid Product Name
get_baseboard_hw_product_name() {
    local i2c_bus="$1"
    local fru_addr="$2"
    local output
    # default i2c_bus to 3 (I2C-4), FRU address to 0x53 (FPGA exposed)
    bus=${i2c_bus:-3} && addr=${fru_addr:-0x53}
    if [[ -f "/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom" ]]; then
        output=$(_log_ dd if=/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom bs=1 skip=86 count=9 | hexdump -v -e '/1 "0x%02X "' | tr -d ' ' | sed 's/0x/\\x/g')
    else
        output=$(_log_ i2ctransfer -f -y "$bus" w1@"$addr" 0x56 r9 | tr -d ' ' | sed 's/0x/\\x/g')
    fi
    if [[ -n "$output" && "$output" != *"\xff"* && "$output" != *"\xFF"* ]]; then printf $output; else echo ""; fi
}

# Baseboard-HW-Version-02
# Function to get Serial Number from Baseboard FRU through FPGA
# Arguments:
#   $1: HMC I2C bus where the Basebaord FRU resides
#   $2: Basebaord FRU I2C address
# Return:
#   valid Serial Number
get_baseboard_hw_serial_number() {
    local i2c_bus="$1"
    local fru_addr="$2"
    local output
    # default i2c_bus to 3 (I2C-4), FRU address to 0x53 (FPGA exposed)
    bus=${i2c_bus:-3} && addr=${fru_addr:-0x53}
    if [[ -f "/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom" ]]; then
        output=$(_log_ dd if=/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom bs=1 skip=96 count=13 | hexdump -v -e '/1 "0x%02X "' | tr -d ' ' | sed 's/0x/\\x/g')
    else
        output=$(_log_ i2ctransfer -f -y "$bus" w1@"$addr" 0x60 r13 | tr -d ' ' | sed 's/0x/\\x/g')
    fi
    if [[ -n "$output" && "$output" != *"\xff"* && "$output" != *"\xFF"* ]]; then printf $output; else echo ""; fi
}

# Baseboard-HW-Version-03
# Function to get Part Number from Baseboard FRU through FPGA
# Arguments:
#   $1: HMC I2C bus where the Basebaord FRU resides
#   $2: Basebaord FRU I2C address
# Return:
#   valid Part Number
get_baseboard_hw_part_number() {
    local i2c_bus="$1"
    local fru_addr="$2"
    local output
    # default i2c_bus to 3 (I2C-4), FRU address to 0x53 (FPGA exposed)
    bus=${i2c_bus:-3} && addr=${fru_addr:-0x53}
    if [[ -f "/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom" ]]; then
        output=$(_log_ dd if=/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom bs=1 skip=110 count=18 | hexdump -v -e '/1 "0x%02X "' | tr -d ' ' | sed 's/0x/\\x/g')
    else
        output=$(_log_ i2ctransfer -f -y "$bus" w1@"$addr" 0x6e r18 | tr -d ' ' | sed 's/0x/\\x/g')
    fi
    if [[ -n "$output" && "$output" != *"\xff"* && "$output" != *"\xFF"* ]]; then printf $output; else echo ""; fi
}

# P2312-HW-Version-01
# Function to get P2312 Product Name from HMC FRU through FPGA
# Arguments:
#   $1: HMC I2C bus where the HMC FRU resides
#   $2: HMC FRU I2C address
# Return:
#   valid Product Name
get_p2312_hw_product_name() {
    local i2c_bus="$1"
    local fru_addr="$2"
    local output
    # default i2c_bus to 3 (I2C-4), FRU address to 0x4e (FPGA exposed)
    bus=${i2c_bus:-3} && addr=${fru_addr:-0x4e}
    if [[ -f "/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom" ]]; then
        output=$(_log_ dd if=/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom bs=1 skip=22 count=9 | hexdump -v -e '/1 "0x%02X "' | tr -d ' ' | sed 's/0x/\\x/g')
    else
        output=$(_log_ i2ctransfer -f -y "$bus" w1@"$addr" 0x16 r9 | tr -d ' ' | sed 's/0x/\\x/g')
    fi
    if [[ -n "$output" && "$output" != *"\xff"* && "$output" != *"\xFF"* ]]; then printf $output; else echo ""; fi
}

# P2312-HW-Version-02
# Function to get P2312 Serial Number from HMC FRU through FPGA
# Arguments:
#   $1: HMC I2C bus where the HMC FRU resides
#   $2: HMC FRU I2C address
# Return:
#   valid Serial Number
get_p2312_hw_serial_number() {
    local i2c_bus="$1"
    local fru_addr="$2"
    local output
    # default i2c_bus to 3 (I2C-4), FRU address to 0x4e (FPGA exposed)
    bus=${i2c_bus:-3} && addr=${fru_addr:-0x4e}
    if [[ -f "/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom" ]]; then
        output=$(_log_ dd if=/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom bs=1 skip=32 count=13 | hexdump -v -e '/1 "0x%02X "' | tr -d ' ' | sed 's/0x/\\x/g')
    else
        output=$(_log_ i2ctransfer -f -y "$bus" w1@"$addr" 0x20 r13 | tr -d ' ' | sed 's/0x/\\x/g')
    fi
    if [[ -n "$output" && "$output" != *"\xff"* && "$output" != *"\xFF"* ]]; then printf $output; else echo ""; fi
}

# P2312-HW-Version-03
# Function to get P2312 Part Number from HMC FRU through FPGA
# Arguments:
#   $1: HMC I2C bus where the HMC FRU resides
#   $2: HMC FRU I2C address
# Return:
#   valid Part Number
get_p2312_hw_part_number() {
    local i2c_bus="$1"
    local fru_addr="$2"
    local output
    # default i2c_bus to 3 (I2C-4), FRU address to 0x4e (FPGA exposed)
    bus=${i2c_bus:-3} && addr=${fru_addr:-0x4e}
    if [[ -f "/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom" ]]; then
        output=$(_log_ dd if=/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom bs=1 skip=46 count=18 | hexdump -v -e '/1 "0x%02X "' | tr -d ' ' | sed 's/0x/\\x/g')
    else
        output=$(_log_ i2ctransfer -f -y "$bus" w1@"$addr" 0x2e r18 | tr -d ' ' | sed 's/0x/\\x/g')
    fi
    if [[ -n "$output" && "$output" != *"\xff"* && "$output" != *"\xFF"* ]]; then printf $output; else echo ""; fi
}

# HMC-HMC-Service-01
# Function to verify if the HMC service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_fpga_ready_service_active() {
local service_name="$1"
local output
name=${service_name:-'nvidia-fpga-ready.target'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC-Service-02
# Function to verify if the HMC service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_fpga_ready_monitor_service_active() {
local service_name="$1"
local output
name=${service_name:-'nvidia-fpga-ready-monitor.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC_FLASH-SPI-01
# Function to get HMC Config Flash Part Name through SPI
# Arguments:
#   $1: SPI Bus.Dev number
# Returns:
#   Valid Part Name
get_hmc_flash_part_name_spi() {
local spi_bus_dev="$1"
bus=${spi_bus_dev:-"spi1.0"} && output=$(_log_ cat /sys/bus/spi/devices/"$bus"/spi-nor/partname 2>/dev/null) && echo $output
}

# HMC-HMC_FLASH-SPI-02
# Function to get HMC Config Flash Part Vendor through SPI
# Arguments:
#   $1: SPI Bus.Dev number
# Returns:
#   Valid Part Vendor
get_hmc_flash_part_vendor_spi() {
local spi_bus_dev="$1"
bus=${spi_bus_dev:-"spi1.0"} && output=$(_log_ cat /sys/bus/spi/devices/"$bus"/spi-nor/manufacturer 2>/dev/null) && echo $output
}

## HMC: Transport Protocol

# HMC-HMC-Service-04
# Function to verify if the HMC service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_mctp_pcie_ctrl_service_active() {
local service_name="$1"
local output
name=${service_name:-'mctp-pcie-ctrl.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC-Service-05
# Function to verify if the HMC service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_mctp_pcie_demux_service_active() {
local service_name="$1"
local output
name=${service_name:-'mctp-pcie-demux.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC-Service-06
# Function to verify if the HMC service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_mctp_spi_ctrl_service_active() {
local service_name="$1"
local output
name=${service_name:-'mctp-spi-ctrl.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC-Service-07
# Function to verify if the HMC service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_mctp_spi_demux_service_active() {
local service_name="$1"
local output
name=${service_name:-'mctp-spi-demux.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC-DBUS-01
# Function to get MCTP DBus VDM tree EIDs
# Arguments:
#   n/a
# Returns:
#   flattened list of the MCTP VDM tree EIDs
get_hmc_dbus_mctp_vdm_tree_eids() {
output=$(_log_ busctl tree xyz.openbmc_project.MCTP.Control.PCIe | grep -o '/0/[0-9]\+$' | sed 's/\/0\///') && echo $output
}

# HMC-HMC-DBUS-11
# Function to get MCTP DBus SPI tree EIDs
# Arguments:
#   n/a
# Returns:
#   flattened list of the MCTP SPI tree EIDs
get_hmc_dbus_mctp_spi_tree_eids() {
output=$(_log_ busctl tree xyz.openbmc_project.MCTP.Control.SPI | grep -o '/0/[0-9]\+$' | sed 's/\/0\///') && echo $output
}

# HMC-HMC_EROT-MCTP_VDM-01
# Function to get the enumrated MCTP EID, HMC ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid "14"
get_hmc_erot_mctp_eid_spi() {
local hmc_erot_spi_eid="$1"

# default EID to 14, HMC MCTP ERoT SPI
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${hmc_erot_spi_eid:-14} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-HMC_EROT-MCTP_VDM-02
# Function to get the enumrated MCTP EID, HMC ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid "18"
get_hmc_erot_mctp_eid_i2c() {
local hmc_erot_i2c_eid="$1"

# default EID to 18, Umbriel HMC MCTP ERoT I2C
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${hmc_erot_i2c_eid:-18} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-HMC_EROT-MCTP_VDM-03
# Function to get the MCTP UUID for HMC ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_hmc_erot_mctp_uuid_spi() {
local hmc_erot_spi_eid="$1"

# default EID to 14, HMC MCTP ERoT SPI
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${hmc_erot_spi_eid:-14} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

# HMC-HMC_EROT-MCTP_VDM-04
# Function to get the MCTP UUID for HMC ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_hmc_erot_mctp_uuid_i2c() {
local hmc_erot_i2c_eid="$1"

# default EID to 18, HMC MCTP ERoT I2C
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${hmc_erot_i2c_eid:-18} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

# HMC-HMC_EROT-MCTP_SPI-01
# Function to get
# Function to get the enumrated MCTP EID, HMC ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid "14"
_get_hmc_erot_mctp_eid_spi() {
local hmc_erot_spi_eid="$1"

# default EID to 14, HMC MCTP ERoT SPI
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
# TODO, make the mctp-spi-ctrl work
# https://nvbugs/4405692 [Umbriel][Left-Shift][TS1] mctp-spi-ctrl Segmentation fault
eid=${hmc_erot_spi_eid:-14} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep 'mctp_resp_msg' | grep -o '0x[0-9a-fA-F]\+' | sed -n '5p') && echo $((eid_rt))
}

# HMC-HMC_EROT-DBUS-12
# Function to get HMC ERoT-SPI MCTP UUID via MCTP over SPI through DBus
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid MCTP UUID
get_hmc_dbus_mctp_spi_spi_uuid() {
local eid="$1"
local output

# default EID to 0, HMC ERoT via MCTP over SPI
erot_id=${eid:-0} && output=$(_log_ busctl introspect xyz.openbmc_project.MCTP.Control.SPI /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

# HMC-HMC_EROT-DBUS-13
# Function to get HMC ERoT-SPI MCTP UUID via MCTP over VDM through DBus
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid MCTP UUID
get_hmc_dbus_mctp_vdm_spi_uuid() {
local eid="$1"
local output

# default EID to 14, HMC ERoT via MCTP over VDM
erot_id=${eid:-14} && output=$(_log_ busctl introspect xyz.openbmc_project.MCTP.Control.PCIe /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

# HMC-HMC_EROT-DBUS-14
# Function to get HMC ERoT-I2C MCTP UUID via MCTP over VDM through DBus
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid MCTP UUID
get_hmc_dbus_mctp_vdm_i2c_uuid() {
local eid="$1"
local output

# default EID to 18, HMC ERoT via MCTP over VDM
erot_id=${eid:-18} && output=$(_log_ busctl introspect xyz.openbmc_project.MCTP.Control.PCIe /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

## HMC: Base Protocol

# HMC-HMC_EROT-PLDM_T0-01
# Function to get PLDM base GetTID of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_hmc_erot_pldm_tid() {
local hmc_eid="$1"
eid=${hmc_eid:-14} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-HMC_EROT-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_hmc_erot_pldm_pldmtypes() {
local hmc_eid="$1"
eid=${hmc_eid:-14} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-HMC_EROT-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_hmc_erot_pldm_t0_pldmversion() {
local hmc_eid="$1"
eid=${hmc_eid:-14} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-HMC_EROT-PLDM_T0-04
# Function to get PLDM base GetPLDMVersion T5 of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_hmc_erot_pldm_t5_pldmversion() {
local hmc_eid="$1"
eid=${hmc_eid:-14} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

## HMC: Firmware Update Protocol

# HMC-HMC-Version-01
# Function to get HMC FW version from /etc/os-release
# Arguments:
#   $1: Full version string or not
# Returns:
#   valid HMC FW version
get_hmc_fw_version_file() {
local full_str="$1"
# default false to full_str
full=${full_str:-false} && ver=$(_log_ cat /etc/os-release | grep ^VERSION_ID | cut -d '=' -f 2) && if $full; then echo "$ver"; else echo "$ver" | cut -d '-' -f 1-5; fi
}

# HMC-HMC-Version-02
# Function to get HMC FW version from BMC.Inventory dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid HMC FW version
get_hmc_fw_version_dbus() {
local sw_id="$1"
# default to HGX_FW_BMC_0
id=${sw_id:-HGX_FW_BMC_0} && _log_ busctl get-property xyz.openbmc_project.Software.BMC.Inventory /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-HMC-Service-08
# Function to verify if the HMC service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_pldmd_service_active() {
local service_name="$1"
local output
name=${service_name:-'pldmd.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC_EROT-Version-01
# Function to get HMC ERoT FW version from PLDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_hmc_erot_fw_version_pldm() {
local eid="$1"
local output
# default EID to 14, HMC ERoT
eid=${eid:-14} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-HMC_EROT-Version-02
# Function to get HMC ERoT FW version from PLDM dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid ERoT FW version
get_hmc_erot_fw_version_pldm_dbus() {
local sw_id="$1"
# default HGX_FW_ERoT_BMC_0
id=${sw_id:-HGX_FW_ERoT_BMC_0} && _log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-HMC_EROT-Version-03
# Function to get HMC ERoT FW Build Type
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Build Type
get_hmc_erot_fw_build_type() {
local hmc_erot_eid="$1"
# default 14 to HMC ERoT EID
# 0: rel, 1: dev
eid=${hmc_erot_eid:-14} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build & 0x01) ))

    case "$result" in
        0) echo "rel" ;;
        1) echo "dev" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-HMC_EROT-Version-04
# Function to get HMC ERoT FW Keyset
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Keyset
get_hmc_erot_fw_keyset() {
local hmc_erot_eid="$1"
# default 14 to HMC ERoT EID
# 0: s1, 1: s2, 2: s3, 3: s4, 4: s5
eid=${hmc_erot_eid:-14} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 1) & 0x07 ))

    case "$result" in
        0) echo "s1" ;;
        1) echo "s2" ;;
        2) echo "s3" ;;
        3) echo "s4" ;;
        4) echo "s5" ;;
        5) echo "s6" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-HMC_EROT-Version-05
# Function to get HMC ERoT FW Chip Rev
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Chip Rev
get_hmc_erot_fw_chiprev() {
local hmc_erot_eid="$1"
# default 14 to HMC ERoT EID
# 0: revA, 1:revB
eid=${hmc_erot_eid:-14} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 4) & 0x03 ))

    case "$result" in
        0) echo "revA" ;;
        1) echo "revB" ;;
        2) echo "revC" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-HMC_EROT-Version-06
# Function to get HMC ERoT FW Boot Slot
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Boot Slot
get_hmc_erot_fw_boot_slot() {
local hmc_erot_eid="$1"
# default 14 to HMC ERoT EID
eid=${hmc_erot_eid:-14} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    result=$(( (16#${output[8]} >> 6) & 0x01 ))
    echo "$result"
else
    # Invalid
    echo ""
fi
}

# HMC-HMC_EROT-Version-07
# Function to get HMC ERoT FW EC Identical
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW EC Identical
get_hmc_erot_fw_ec_identical() {
local hmc_erot_eid="$1"
# default 14 to HMC ERoT EID
# 0: identical, 1: not identical
eid=${hmc_erot_eid:-14} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 7) & 0x01 ))
    if [[ "$result" == "0" ]]; then
        echo "identical"
    elif [[ "$result" == "1" ]]; then
        echo "not identical"
    else
        echo ""
    fi
else
    # Invalid
    echo ""
fi
}

# HMC-HMC_EROT-PLDM_T5-01
# Function to get PLDM fw_update version of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_hmc_erot_pldm_version() {
local eid="$1"
# default EID to 14, HMC ERoT
eid=${eid:-14} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-HMC_EROT-PLDM_T5-02
# Function to get PLDM fw_update version of HMC
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid FW version
get_hmc_erot_pldm_version_string() {
local eid="$1"
# default EID to 14, HMC ERoT
eid=${eid:-14} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==2') && echo $output
}

# HMC-HMC_EROT-PLDM_T5-05
# Function to get PLDM fw_update AP_SKU ID of HMC
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_hmc_erot_pldm_apsku_id() {
local sku_eid="$1"
# default EID to 14, HMC ERoT
eid=${sku_eid:-14} && key=${sku_key:-APSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-HMC_EROT-PLDM_T5-06
# Function to get PLDM fw_update EC_SKU ID of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC_SKU ID
get_hmc_erot_pldm_ecsku_id() {
local sku_eid="$1"
# default EID to 14, HMC ERoT
eid=${sku_eid:-14} && key=${sku_key:-ECSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-HMC_EROT-PLDM_T5-07
# Function to get PLDM fw_update GLACIERDSD of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid GLACIERDSD ID
get_hmc_erot_pldm_glacier_id() {
local sku_eid="$1"
# default EID to 14, HMC ERoT
eid=${sku_eid:-14} && key=${sku_key:-GLACIERDSD} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-HMC-DBUS-02
# Function to get PLDM DBus tree inventory IDs
# Arguments:
#   n/a
# Returns:
#   flattened list of the PLDM tree inventory IDs
get_dbus_pldm_tree_ids() {
output=$(_log_ busctl tree xyz.openbmc_project.PLDM | grep chassis | grep -o '[A-Za-z0-9_]*_[0-9]') && echo $output
}

# HMC-HMC_EROT-DBUS-03
# Function to get PLDM DBus chassis inventory UUID of HMC ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid MCTP UUID
get_hmc_dbus_pldm_hmc_erot_uuid() {
local hmc_pldm_erotid="$1"
erot_id=${hmc_pldm_erot_id:-HGX_ERoT_BMC_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/inventory/system/chassis/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

## HMC: Telemetry Protocol

# HMC-HMC-Service-03
# Function to verify if the HMC service is inactive
# Arguments:
#   $1: Service name
# Returns:
#   valid "no", "yes" otherwise
is_hmc_gpu_manager_service_inactive() {
local service_name="$1"
local output
name=${service_name:-'nvidia-gpu-manager.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'inactive' ]] && echo "yes" || echo "no"
}

# HMC-HMC-Service-11
# Function to verify if the HMC service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_nsmd_service_active() {
local service_name="$1"
local output
name=${service_name:-'nsmd.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC-PLDM_T2-01
# Function to get PLDM T2 sensor polling status
# Arguments:
#   n/a
# Returns:
#   valid "yes", "no" otherwise
is_hmc_pldm_t2_sensor_polling_enabled() {
local output
output=$(_log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled | cut -d ' ' -f 2); [[ $output = "true" ]] && echo "yes" || echo "no"
}

## HMC: Security Protocol

# HMC-HMC-Service-09
# Function to verify if the HMC service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_debugtoken_erase_service_active() {
local service_name="$1"
local output
name=${service_name:-'com.Nvidia.DebugTokenErase.Updater.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC-Service-10
# Function to verify if the HMC service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_debugtoken_install_service_active() {
local service_name="$1"
local output
name=${service_name:-'com.Nvidia.DebugTokenInstall.Updater.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC-DBUS-10
# Function to get SPDM DBus tree IDs
# Arguments:
#   n/a
# Returns:
#   flattened list of the SPDM tree IDs
get_dbus_spdm_tree_ids() {
output=$(_log_ busctl tree xyz.openbmc_project.SPDM | grep -o '[A-Za-z0-9_]*_[0-9]') && echo $output
}

# HMC-HMC-IROT-01
# Function to get IROT Secure Boot Status
# Arguments:
#   $1: file descriptor path to the secure boot status
# Returns:
#   valid secure boot status
get_hmc_irot_secure_boot_status() {
local fd_path="$1"
path=${fd_path:-"/var/lib/otp-provisioning/status"} && output=$(_log_ cat $path | head -n 1) && [[ $output = '1' ]] && echo "enabled" || echo "disabled"
}

# HMC-HMC-IROT-02
# Function to get IROT OTP Enable Secure Boot config
# Arguments:
#   $1: mask bit to get the config
# Returns:
#   valid "yes", "no" otherwise
is_hmc_irot_otp_secure_boot_enable_configured() {
local mask_bit="$1"
mask=${mask_bit:-"1"} && out=$(_log_ otp read conf 0x00 1 | head -n 1 | cut -d ':' -f 2 | tr -d ' ') && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
}

# HMC-HMC-IROT-03
# Function to get IROT OTP Enable Secure Boot config
# Arguments:
#   $1: mask bit to get the config
# Returns:
#   valid "yes", "no" otherwise
is_hmc_irot_otp_secure_boot_ignore_hw_strap_configured() {
local mask_bit="$1"
mask=${mask_bit:-"6"} && out=$(_log_ otp read conf 0x00 1 | head -n 1 | cut -d ':' -f 2 | tr -d ' ') && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
}

# HMC-HMC_EROT-SPDM-01
# Function to get SPDM Version through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Version
get_hmc_erot_spdm_version() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_BMC_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Version | cut -d ' ' -f 2) && echo $output
}

# HMC-HMC_EROT-SPDM-02
# Function to get SPDM Measurements Type through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Measurements Type
get_hmc_erot_spdm_measurements_type() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_BMC_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder MeasurementsType | tr -d '"' | cut -d '.' -f 6) && echo $output
}

# HMC-HMC_EROT-SPDM-03
# Function to get SPDM Algorithms through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Algorithms
get_hmc_erot_spdm_hash_algorithms() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_BMC_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder HashingAlgorithm | cut -d ' ' -f 2 | cut -d '.' -f 6 | tr -d '"')
id=${spdm_id:-'HGX_ERoT_BMC_0'} && output+=" $(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder SigningAlgorithm | cut -d ' ' -f 2 | cut -d '.' -f 6 | tr -d '"')"
echo "$output"
}

# HMC-HMC_EROT-SPDM-04
# Function to get SPDM Measurement of Serial Number (index 27)
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid "yes", "no" otherwise
get_hmc_erot_spdm_measurement_serial_number() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_BMC_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Measurements) && [[ -n $output ]] && echo "yes" || echo "no"
}

# HMC-HMC_EROT-SPDM-05
# Function to get SPDM Measurement of Token Request (index 50)
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid "yes", "no" otherwise
get_hmc_erot_spdm_measurement_token_request() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_BMC_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Measurements) && [[ -n $output ]] && echo "okay" || echo "no"
}

# HMC-HMC_EROT-SPDM-06
# Function to get SPDM Certificate count through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Certificate count
get_hmc_erot_spdm_certificate_count() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_BMC_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Certificate | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $output
}

# Component-Level Category: FPGA #
## FPGA: Hardware Interface

# HMC-FPGA-PCIe-01
# Function to get PCIe speed of FPGA
# Arguments:
#   $1: FPGA PCIe BDF
# Returns:
#   valid "Speed 5GT/s"
get_fpga_pci_speed() {
local FPGA_BDF="$1"
# default 1:00.0 to FPGA BDF
FPGA_BDF=${FPGA_BDF:-'1:00.0'} && _log_ lspci -vv -s $FPGA_BDF | grep LnkSta: | grep -o 'Speed [^,]\+'
}

# HMC-FPGA-PCIe-02
# Function to get PCIe width of FPGA
# Arguments:
#   $1: FPGA PCIe BDF
# Returns:
#   valid "Width x1"
get_fpga_pci_width() {
local FPGA_BDF="$1"
# default 1:00.0 to FPGA BDF
FPGA_BDF=${FPGA_BDF:-'1:00.0'} && _log_ lspci -vv -s $FPGA_BDF | grep LnkSta: | grep -o 'Width [^,]\+'
}

# HMC-FPGA-PCIe-10
# Function to check if the FPGA EP is present over the PCIe Link
# Arguments:
#   $1: FPGA MMIO address
# Returns:
#   valid "yes", "no" otherwise
is_fpga_pci_ep_presence() {
local fpga_mmio_address="$1"
# default 0x70000000 to FPGA EP MMIO
mmio_addr=${fpga_mmio_address:-'0x70000000'} && command -v "devmem" &> /dev/null && output=$(_log_ devmem "$mmio_addr" w); [ $output = "0x00000001" ] && echo "yes" || echo "no"
}

# HMC-FPGA-GPIO-01
# Function to verify GPIO Input of FPGA_MIDP_HGX_PWR_GD through register table
# Arguments:
#   n/a
# Returns:
#   set "yes", "no" otherwise
is_fpga_midp_hgx_pwr_gd_set_regtable() {
# bit mask for the bit 0
local mask=1
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local hmcsts_reg="${4:-0x36}"
if [ "$bytes_to_write" = 2 ] ;
then
    # default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
    out=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x77 0x00 r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
else
    out=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" $hmcsts_reg r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
fi
}

# HMC-FPGA-GPIO-02
# Function to verify GPIO Input of FPGA_MIDP_HGX_FPGA_READY through register table
# Arguments:
#   n/a
# Returns:
#   set "yes", "no" otherwise
is_fpga_midp_hgx_fpga_ready_set_regtable() {
# bit mask for the bit 1
local mask=2
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local hmcsts_reg="${4:-0x36}"
if [ "$bytes_to_write" = 2 ] ;
then
    # default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
    out=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x77 0x00 r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
else
    out=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" $hmcsts_reg r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
fi
}

# HMC-FPGA-GPIO-03
# Function to verify GPIO Input of FPGA_MIDP_THERM_OVERT_L through register table
# Arguments:
#   n/a
# Returns:
#   set "yes", "no" otherwise
is_fpga_midp_therm_overt_not_set_regtable() {
# bit mask for the bit 2
local mask=4
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local hmcsts_reg="${4:-0x36}"
if [ "$bytes_to_write" = 2 ] ;
then
    # default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
    out=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x77 0x00 r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
else
    out=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" $hmcsts_reg r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
fi
}

# HMC-FPGA-GPIO-04
# Function to verify GPIO Input of FPGA_HMC_I2C3_ALERT_L through register table
# Arguments:
#   n/a
# Returns:
#   set "yes", "no" otherwise
is_fpga_hmc_i2c3_alert_not_set_regtable() {
# bit mask for the bit 5
local mask=32
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local hmcsts_reg="${4:-0x36}"
if [ "$bytes_to_write" = 2 ]
then
    # default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
    out=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x72 0x00 r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
else
    out=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" $hmcsts_reg r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
fi
}

# HMC-FPGA-GPIO-05
# Function to verify GPIO Input of FPGA_HMC_I2C4_ALERT_L through register table
# Arguments:
#   n/a
# Returns:
#   set "yes", "no" otherwise
is_fpga_hmc_i2c4_alert_not_set_regtable() {
# bit mask for the second bit
# bit mask for the bit 6
local mask=64
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local hmcsts_reg="${4:-0x36}"
if [ "$bytes_to_write" = 2 ]
then
    out=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x72 0x00 r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
else
    out=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" $hmcsts_reg r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
fi
}

# HMC-FPGA-GPIO-06
# Function to check if the FPGA GPI (fpga_ready) is set, Active High
# Arguments:
#   n/a
# Returns:
#   set "yes", "no" otherwise
is_fpga_gpio_fpga_ready_set() {
    # The nvidia-fpga-ready-monitor.service utilizes the fpga_ready GPI.
    # Stop the service before making attempt to access the fpga_ready GPI.
    systemctl stop nvidia-fpga-ready-monitor.service >/dev/null 2>&1
    sleep 1
    output=$(_log_ gpioget `gpiofind "fpga_ready"`); [ "$output" = "1" ] && echo "yes" || echo "no"
    sleep 1
    systemctl start nvidia-fpga-ready-monitor.service >/dev/null 2>&1
}

# HMC-FPGA-I2C-01
# Function to get I2C devices from I2C-3
# Arguments:
#   $1: I2C Bus number for the HMC I2C-3
# Returns:
#   flattened list of the I2C device address
get_hmc_fpga_i2c3_devices() {
local i2c_bus="$1"
bus=${i2c_bus:-2} && output=$(_log_ i2cdetect -q -y "$bus" | awk '{for(i=1; i<=NF; i++) if ($i ~ /^[0-9a-fA-F]{2}$/) print $i}') && echo $output
}

# HMC-FPGA-I2C-02
# Function to get I2C devices from I2C-4
# Arguments:
#   $1: I2C Bus number for the HMC I2C-4
# Returns:
#   flattened list of the I2C device address
get_hmc_fpga_i2c4_devices() {
local i2c_bus="$1"
bus=${i2c_bus:-3} && output=$(_log_ i2cdetect -q -y "$bus" | awk '{for(i=1; i<=NF; i++) if ($i ~ /^[0-9a-fA-F]{2}$/) print $i}') && echo $output
}

# HMC-FPGA-I2C-05
# Function to dump FPGA register table from I2C-3
# Arguments:
#   $1: I2C Bus number for the HMC I2C-3
#   $2: I2C Addr for the FPGA register table
# Returns:
#   valid HMC FW version
get_fpga_regtable() {
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local output
if [ "$bytes_to_write" = 2 ] ;
then
    # default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
    output=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x00 0x00 r256 | sed 's/0x//g' | egrep -o '.{1,48}') && echo "done" || echo "failed"
else
    output=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" 0x00 r256 | sed 's/0x//g' | egrep -o '.{1,48}') && echo "done" || echo "failed"
fi
}

## FPGA: Transport Protocol

# HMC-FPGA-MMIO_SMBPBI-01
# Function to get FPGA version through SMBPBI Proxy
# Arguments:
#   $1: FPGA MMIO address
# Returns:
#   valid FPGA version
get_fpga_version_mmio_smbpbi_proxy() {
    local fpga_mmio_address="$1"

    # default 0x70000000 to FPGA EP MMIO
    addr=${fpga_mmio_address:-'0x70000000'}

    if [ -x "$(command -v devmem)" ]; then
        devmem "$addr" w &> /dev/null  # 0x00000001 means FPGA present

        # The SMBPBI (05h, Arg1 88h)
        devmem $(printf "0x%x" $(($addr+0x7c)))  w 0x80008805
        devmem $(printf "0x%x" $(($addr+0x110))) w 0xC0000000
        devmem $(printf "0x%x" $(($addr+0x100))) w 0x80000000
        devmem $(printf "0x%x" $(($addr+0xfc)))  w &> /dev/null  # 0x1F008805, RC=1F
        _log_ devmem $(printf "0x%x" $(($addr+0xf8)))  w  # version data out
    fi
}

# HMC-FPGA-VFIO_SMBPBI-01
# Function to get FPGA version through VFIO SMBPBI Proxy
# Arguments:
#   $1: GPU Manager Object ID
# Returns:
#   valid FPGA version
get_fpga_version_vfio_smbpbi_proxy() {
# default to HGX_FW_FPGA_0
sw_id="$1"
id=${sw_id:-HGX_FW_FPGA_0} && _log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-FPGA-VFIO_SMBPBI-02
# Function to get FPGA PCIe Power State through VFIO SMBPBI Proxy
# Arguments:
#   $1: System ID
# Returns:
#   valid "On" state
get_fpga_pcie_power_state_vfio_smbpbi_proxy() {
local system_id="$1"
# default to PCIeToHMC_0
id=${system_id:-PCIeToHMC_0} && output=$(_log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/inventory/system/processors/FPGA_0/Ports/"${id}" xyz.openbmc_project.State.Chassis CurrentPowerState | cut -d ' ' -f 2 | tr -d '"' | cut -d '.' -f 6) && echo $output
}

# HMC-FPGA-VFIO_SMBPBI-03
# Function to get FPGA temperature through VFIO SMBPBI Proxy
# Arguments:
#   $1: callback ID
# Returns:
#   valid FPGA temperature
get_fpga_temperature_vfio_smbpbi_proxy() {
local callback_id="$1"
# default to fpga.thermal.temperature.extendedPrecision
# use the call parameter "1" to go with passthrough mode
id=${callback_id:-fpga.thermal.temperature.extendedPrecision} && _log_ busctl call xyz.openbmc_project.GpuMgr /xyz/openbmc_project/GpuMgr xyz.openbmc_project.GpuMgr.Server DeviceGetData isi 0 "$id" 1 | cut -d ' ' -f 6
}

# HMC-FPGA-I2C_SMBPBI-01
# Function to get FPGA FW version through SMBPBI on I2C-4 bus
# Arguments:
#   $1: I2C Bus number for the BMC I2C-4 (i2c 3)
#   $2: I2C Addr for the FPGA SMBPBI server
#   $3: Register Addr for the target component
# Returns:
#   valid FPGA FW version
get_fpga_version_i2c_smbpbi() {
local i2c_bus="$1"
local i2c_addr="$2"
local register="$3"
local output
# default 3 to i2c bus number, 0x60 to i2c address for the SMBPBI server
# default 0x88 to the register address, FPGA
bus=${i2c_bus:-3} && addr=${i2c_addr:-0x60} && reg=${register:-0x88} && output=$(_log_ i2ctransfer -f -y "$bus" w6@"$addr" 0x5c 0x04 0x05 "$reg" 0x00 0x80; i2ctransfer -f -y "$bus" w1@"$addr" 0x5d r5 | cut -d ' ' -f 2-6) && echo "$output"
}

# HMC-FPGA-I2C_SMBPBI-02
# Function to get Retimer FW version through SMBPBI on I2C-4 bus
# Arguments:
#   $1: I2C Bus number for the BMC I2C-4 (i2c 3)
#   $2: I2C Addr for the FPGA SMBPBI server
#   $3: Register Addr for the target component
# Returns:
#   valid Retimer FW version
get_retimer_version_i2c_smbpbi() {
local i2c_bus="$1"
local i2c_addr="$2"
local register="$3"
local output

# default 3 to i2c bus number, 0x60 to i2c address for the SMBPBI server
# default 0x90 to the register address, Retimer #1
bus=${i2c_bus:-3} && addr=${i2c_addr:-0x60} && reg=${register:-0x90} && output=$(_log_ i2ctransfer -f -y "$bus" w6@"$addr" 0x5c 0x04 0x05 "$reg" 0x00 0x80; i2ctransfer -f -y "$bus" w1@"$addr" 0x5d r5 | cut -d ' ' -f 2-6) && echo "$output"
}

# HMC-FPGA-MCTP_VDM-01
# Function to verify if FPGA VDM is operational
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "yes", "no" otherwise
is_fpga_vdm_operational() {
local eid="$1"

# default EID to 13, FPGA ERoT
# selftest parameters "0 0 0 0" is to get version only
eid=${eid:-13} && if _log_ mctp-vdm-util -t "$eid" -c selftest 0 0 0 0 >/dev/null 2>&1; then echo "yes"; else echo "no"; fi
}

# HMC-FPGA-MCTP_VDM-02
# Function to get MCTP tree EIDs
# Arguments:
#   n/a
# Returns:
#   flattened list of the MCTP tree EIDs
get_hmc_mctp_eids_tree() {
output=$(_log_ busctl tree xyz.openbmc_project.MCTP.Control.PCIe | grep -o '/0/[0-9]\+$' | sed 's/\/0\///') && echo $output
}

# HMC-FPGA-MCTP_VDM-03
# Function to verify MCTP routing table exists in FPGA MCTP Bridge
# Arguments:
#   $1: MCTP EID to verify the routing table to get from
# Returns:
#   valid "yes", "no" otherwise
is_fpga_mctp_routing_table_existed() {
local fpga_bridge_eid="$1"

# default EID to 12, FPGA MCTP Bridge
# get first entry of the routing table entries
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${fpga_bridge_eid:-12} && [[ "00" = $(_log_ mctp-pcie-ctrl -s "00 80 0a 00" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f4) ]] && echo "yes" || echo "no"
}

# HMC-FPGA-MCTP_VDM-04
# Function to verify MCTP UUID exists for FPGA ERoT
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid "yes", "no" otherwise
is_fpga_mctp_uuid_existed() {
local fpga_erot_eid="$1"

# default EID to 13, FPGA ERoT EID
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${fpga_erot_eid:-13} && [[ "00" = $(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f4) ]] && echo "yes" || echo "no"
}

# HMC-FPGA-MCTP_VDM-05
# Function to get the enumrated MCTP EID, FPGA Bridge
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid "12"
get_fpga_eid_fpga_bridge() {
local fpga_bridge_eid="$1"

# default EID to 12, FPGA MCTP Bridge
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${fpga_bridge_eid:-12} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-FPGA-MCTP_VDM-06
# Function to get the MCTP UUID for FPGA Bridge
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_fpga_mctp_uuid_fpga_bridge() {
local fpga_bridge_eid="$1"

# default EID to 12, FPGA MCTP Bridge
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${fpga_bridge_eid:-12} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

# HMC-FPGA_EROT-MCTP_VDM-01
# Function to get the enumrated MCTP EID, FPGA ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid "13"
get_fpga_erot_mctp_eid_spi() {
local fpga_erot_spi_eid="$1"

# default EID to 13, FPGA MCTP ERoT SPI
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${fpga_erot_spi_eid:-13} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-FPGA_EROT-MCTP_VDM-03
# Function to get the MCTP UUID for FPGA ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_fpga_erot_mctp_uuid_spi() {
local fpga_erot_spi_eid="$1"

# default EID to 13, FPGA MCTP ERoT SPI
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${fpga_erot_spi_eid:-13} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

## FPGA: Base Protocol

# HMC-FPGA_EROT-PLDM_T0-01
# Function to get PLDM base GetTID of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_fpga_erot_pldm_tid() {
local fpga_eid="$1"
eid=${fpga_eid:-13} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-FPGA_EROT-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_fpga_erot_pldm_pldmtypes() {
local fpga_eid="$1"
eid=${fpga_eid:-13} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-FPGA_EROT-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_fpga_erot_pldm_t0_pldmversion() {
local fpga_eid="$1"
eid=${fpga_eid:-13} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-FPGA_EROT-PLDM_T0-04
# Function to get PLDM base GetPLDMVersion T5 of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_fpga_erot_pldm_t5_pldmversion() {
local fpga_eid="$1"
eid=${fpga_eid:-13} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-FPGA-NSM_T0-01
# Function to verify if NSM PING functional via MCTP VDM
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "yes", "no" otherwise
is_fpga_mctp_vdm_nsm_ping_operational() {
local fpga_bridge_eid="$1"
local cmd=00

# default EID to 12, FPGA MCTP Bridge EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${fpga_bridge_eid:-12} && [[ "00" = $(_log_ mctp-pcie-ctrl -s "7e 10 de 80 89 00 $cmd 00" -t 2 -e "${eid}" -i 9 -p 12 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f8) ]] && echo "yes" || echo "no"
}

# HMC-FPGA-NSM_T0-02
# Function to verify if NSM PING functional using nsmtool
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "yes", "no" otherwise
is_fpga_mctp_nsmtool_ping_operational() {
local fpga_bridge_eid="$1"
local cmd=0x00

# default EID to 12, FPGA MCTP Bridge EID
# the 'nsmtool' outputs to journal log
eid=${fpga_bridge_eid:-12} && [[ "00" = $(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '7p') ]] && echo "yes" || echo "no"
}

# HMC-FPGA-NSM_T0-03
# Function to verify NSM Get Supported Message Types via MCTP VDM
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "0x3d", fault otherwise
get_fpga_mctp_vdm_nsm_supported_message_types() {
local fpga_bridge_eid="$1"
local cmd=01

# default EID to 12, FPGA MCTP Bridge EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${fpga_bridge_eid:-12} && output=$(_log_ mctp-pcie-ctrl -s "7e 10 de 80 89 00 $cmd 00" -t 2 -e "${eid}" -i 9 -p 12 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f13) && echo "$output"
}

# HMC-FPGA-NSM_T0-04
# Function to verify NSM Get Supported Message Types using nsmtool
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "0x3d", fault otherwise
get_fpga_mctp_nsmtool_supported_message_types() {
local fpga_bridge_eid="$1"
local cmd=0x01

# default EID to 12, FPGA MCTP Bridge EID
# the 'nsmtool' outputs to journal log
eid=${fpga_bridge_eid:-12} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12p') && [[ $output ]] && echo "$output" || echo ""
}

## FPGA: Firmware Update Protocol

# HMC-FPGA-Version-01
# Function to get FPGA FW version from FPGA Register Table
# Arguments:
#   $1: I2C Bus number for the HMC I2C-3
#   $2: I2C Addr for the FPGA register table
# Returns:
#   valid HMC FW version
get_fpga_fw_version_regtable() {
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local fw_major_version_reg="${4:-0x4c}"
local output
if [ "$bytes_to_write" = 2 ] ;
then
    # default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
    output=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x04 0x00 r3) && echo "$output"
else
    output=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" $fw_major_version_reg r3) && echo "$output"
fi
}

# HMC-FPGA-Version-02
# Function to get FPGA FW version CL from FPGA Register Table
# Arguments:
#   $1: I2C Bus number for the HMC I2C-3
#   $2: I2C Addr for the FPGA register table
# Returns:
#   valid HMC FW version
get_fpga_fw_version_regtable_cl() {
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local output
if [ "$bytes_to_write" = 2 ] ;
then 
    # default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
    output=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x00 0x00 r4) && echo "$output"
else
    output=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" 0x64 r4) && echo "$output"
fi
}

# HMC-FPGA-Version-03
# Function to get FPGA FW version from GPUMgr dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid FPGA FW version
get_fpga_fw_version_gpumgr() {
local sw_id="$1"
# default HGX_FW_FPGA_0
id=${sw_id:-HGX_FW_FPGA_0} && _log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-FPGA_EROT-Version-01
# Function to get FPGA ERoT FW version from PLDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_fpga_erot_fw_version_pldm() {
local eid="$1"
# default EID to 13, FPGA ERoT
eid=${eid:-13} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-FPGA_EROT-Version-02
# Function to get HMC ERoT FW version from PLDM dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid ERoT FW version
get_fpga_erot_fw_version_pldm_dbus() {
local sw_id="$1"
# default HGX_FW_ERoT_FPGA_0
id=${sw_id:-HGX_FW_ERoT_FPGA_0} && _log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-FPGA_EROT-Version-03
# Function to get FPGA ERoT FW Build Type
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Build Type
get_fpga_erot_fw_build_type() {
local fpga_erot_eid="$1"
# default 13 to FPGA ERoT EID
# 0: rel, 1: dev
eid=${fpga_erot_eid:-13} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build & 0x01) ))

    case "$result" in
        0) echo "rel" ;;
        1) echo "dev" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-FPGA_EROT-Version-04
# Function to get FPGA ERoT FW Keyset
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Keyset
get_fpga_erot_fw_keyset() {
local fpga_erot_eid="$1"
# default 13 to FPGA ERoT EID
# 0: s1, 1: s2, 2: s3, 3: s4, 4: s5
eid=${fpga_erot_eid:-13} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 1) & 0x07 ))

    case "$result" in
        0) echo "s1" ;;
        1) echo "s2" ;;
        2) echo "s3" ;;
        3) echo "s4" ;;
        4) echo "s5" ;;
        5) echo "s6" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-FPGA_EROT-Version-05
# Function to get FPGA ERoT FW Chip Rev
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Chip Rev
get_fpga_erot_fw_chiprev() {
local fpga_erot_eid="$1"
# default 13 to FPGA ERoT EID
# 0: revA, 1:revB
eid=${fpga_erot_eid:-13} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 4) & 0x03 ))

    case "$result" in
        0) echo "revA" ;;
        1) echo "revB" ;;
        2) echo "revC" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-FPGA_EROT-Version-06
# Function to get FPGA ERoT FW Boot Slot
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Boot Slot
get_fpga_erot_fw_boot_slot() {
local fpga_erot_eid="$1"
# default 13 to FPGA ERoT EID
eid=${fpga_erot_eid:-13} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    result=$(( (16#${output[8]} >> 6) & 0x01 ))
    echo "$result"
else
    # Invalid
    echo ""
fi
}

# HMC-FPGA_EROT-Version-07
# Function to get FPGA ERoT FW EC Identical
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW EC Identical
get_fpga_erot_fw_ec_identical() {
local fpga_erot_eid="$1"
# default 13 to FPGA ERoT EID
# 0: identical, 1: not identical
eid=${fpga_erot_eid:-13} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 7) & 0x01 ))
    if [[ "$result" == "0" ]]; then
        echo "identical"
    elif [[ "$result" == "1" ]]; then
        echo "not identical"
    else
        echo ""
    fi
else
    # Invalid
    echo ""
fi
}

# HMC-FPGA_EROT-PLDM_T5-01
# Function to get PLDM fw_update version of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_fpga_erot_pldm_version() {
local eid="$1"
# default EID to 13, FPGA ERoT
eid=${eid:-13} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-FPGA_EROT-PLDM_T5-02
# Function to get PLDM fw_update version of FPGA
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid FW version
get_fpga_erot_pldm_version_string() {
local eid="$1"
# default EID to 13, FPGA ERoT
eid=${eid:-13} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==2') && echo $output
}

# HMC-FPGA_EROT-PLDM_T5-05
# Function to get PLDM fw_update AP_SKU ID of FPGA
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_fpga_erot_pldm_apsku_id() {
local sku_eid="$1"
# default EID to 13, FPGA ERoT
eid=${sku_eid:-13} && key=${sku_key:-APSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-FPGA_EROT-PLDM_T5-06
# Function to get PLDM fw_update EC_SKU ID of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC_SKU ID
get_fpga_erot_pldm_ecsku_id() {
local sku_eid="$1"
# default EID to 13, FPGA ERoT
eid=${sku_eid:-13} && key=${sku_key:-ECSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-FPGA_EROT-PLDM_T5-07
# Function to get PLDM fw_update GLACIERDSD of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid GLACIERDSD ID
get_fpga_erot_pldm_glacier_id() {
local sku_eid="$1"
local output
# default EID to 13, FPGA ERoT
eid=${sku_eid:-13} && key=${sku_key:-GLACIERDSD} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-FPGA_EROT-DBUS-04
# Function to get PLDM DBus chassis inventory UUID of FPGA ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid MCTP UUID
get_hmc_dbus_pldm_fpga_erot_uuid() {
local fpga_pldm_erot_id="$1"
erot_id=${fpga_pldm_erot_id:-HGX_ERoT_FPGA_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/inventory/system/chassis/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

# HMC-HMC_EROT-DBUS-05
# Function to get PLDM DBus software inventory version of HMC ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid ERoT FW version
get_hmc_dbus_pldm_hmc_erot_version() {
local hmc_pldm_erot_id="$1"
erot_id=${hmc_pldm_erot_id:-HGX_FW_ERoT_BMC_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$erot_id" | grep '.Version' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

# HMC-FPGA_EROT-DBUS-06
# Function to get PLDM DBus software inventory version of FPGA ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid ERoT FW version
get_hmc_dbus_pldm_fpga_erot_version() {
local fpga_pldm_erot_id="$1"
erot_id=${fpga_pldm_erot_id:-HGX_FW_ERoT_FPGA_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$erot_id" | grep '.Version' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

## FPGA: Telemetry Protocol

# HMC-FPGA-SMBPBI-01
# Function to verify if SMBPBI Fencing Privilege is on HMC
# Arguments:
#   $1: I2C Bus number for the HMC I2C-3
#   $2: I2C Addr for the FPGA register table
# Returns:
#   valid "yes", "no" otherwise
is_hmc_with_smbpbi_fencing_privilege() {
local i2c_bus="$1"
local i2c_addr="$2"

# default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
bus=${i2c_bus:-2} && addr=${i2c_addr:-0x0b} && output=$(_log_ i2ctransfer -y "$bus" w1@"$addr" 0x30 r1) && [[ "$output" = "0x01" ]] && echo "yes" || echo "no"
}

## FPGA: Security Protocol

# HMC-FPGA_EROT-SPDM-01
# Function to get SPDM Version through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Version
get_fpga_erot_spdm_version() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_FPGA_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Version | cut -d ' ' -f 2) && echo $output
}

# HMC-FPGA_EROT-SPDM-02
# Function to get SPDM Measurements Type through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Measurements Type
get_fpga_erot_spdm_measurements_type() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_FPGA_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder MeasurementsType | tr -d '"' | cut -d '.' -f 6) && echo $output
}

# HMC-FPGA_EROT-SPDM-03
# Function to get SPDM Algorithms through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Algorithms
get_fpga_erot_spdm_hash_algorithms() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_FPGA_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder HashingAlgorithm | cut -d ' ' -f 2 | cut -d '.' -f 6 | tr -d '"')
id=${spdm_id:-'HGX_ERoT_FPGA_0'} && output+=" $(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder SigningAlgorithm | cut -d ' ' -f 2 | cut -d '.' -f 6 | tr -d '"')"
echo "$output"
}

# HMC-FPGA_EROT-SPDM-04
# Function to get SPDM Measurement of Serial Number (index 27)
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid "yes", "no" otherwise
get_fpga_erot_spdm_measurement_serial_number() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_FPGA_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Measurements) && [[ -n $output ]] && echo "yes" || echo "no"
}

# HMC-FPGA_EROT-SPDM-05
# Function to get SPDM Measurement of Token Request (index 50)
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid "yes", "no" otherwise
get_fpga_erot_spdm_measurement_token_request() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_FPGA_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Measurements) && [[ -n $output ]] && echo "okay" || echo "no"
}

# HMC-FPGA_EROT-SPDM-06
# Function to get SPDM Certificate count through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Certificate count
get_fpga_erot_spdm_certificate_count() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_FPGA_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Certificate | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $output
}

## GPU: Transport Protocol

# HMC-GPU-VFIO_SMBPBI-01
# Function to get GPU FW version through VFIO SMBPBI Proxy
# Arguments:
#   $1: Software ID
# Returns:
#   valid GPU version
get_gpu_version_vfio_smbpbi_proxy() {
local sw_id="$1"
# default to HGX_FW_GPU_SXM5
id=${sw_id:-HGX_FW_GPU_SXM5} && _log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-GPU-VFIO_SMBPBI-02
# Function to get GPU PCIe lane in use through VFIO SMBPBI Proxy
# Arguments:
#   $1: Chassis ID
# Returns:
#   valid lane/width number
get_gpu_pcie_width_vfio_smbpbi_proxy() {
local chassis_id="$1"
# default to GPU_SXM_5
id=${chassis_id:-GPU_SXM_5} && output=$(_log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/inventory/system/chassis/HGX_$id/PCIeDevices/$id xyz.openbmc_project.Inventory.Item.PCIeDevice LanesInUse | cut -d ' ' -f 2 | tr -d '"') && echo $output
}

# HMC-GPU-VFIO_SMBPBI-03
# Function to get GPU temperature through VFIO SMBPBI Proxy
# Arguments:
#   $1: callback ID
# Returns:
#   valid GPU temperature
get_gpu_temperature_vfio_smbpbi_proxy() {
local callback_id="$1"
# default to gpu.thermal.temperature.extendedPrecision, the GPU #1
# use the call parameter "1" to go with passthrough mode
id=${callback_id:-gpu.thermal.temperature.extendedPrecision} && _log_ busctl call xyz.openbmc_project.GpuMgr /xyz/openbmc_project/GpuMgr xyz.openbmc_project.GpuMgr.Server DeviceGetData isi 0 "$id" 1 | cut -d ' ' -f 6
}

# HMC-GPU-I2C_SMBPBI-01
# Function to get GPU FW version through SMBPBI on I2C-3 bus
# Arguments:
#   $1: I2C Bus number for the BMC I2C-3 (i2c 2)
#   $2: I2C Addr for the GPU SMBPBI server
#   $3: Register Addr for the target component
# Returns:
#   valid GPU FW version
get_gpu_version_i2c_smbpbi() {
local i2c_bus="$1"
local i2c_addr="$2"
local register="$3"
local output

# default 2 to i2c bus number, 0x69 to i2c address for the SMBPBI server, SXM5
# default 0x8 to the register address, FW version
bus=${i2c_bus:-2} && addr=${i2c_addr:-0x69} && reg=${register:-0x8} && output=$(_log_ i2ctransfer -f -y "$bus" w6@"$addr" 0x5c 0x04 0x05 "$reg" 0x00 0x80; i2ctransfer -f -y "$bus" w1@"$addr" 0x5d r14 | cut -d ' ' -f 2-6) && echo "$output"
}

# HMC-GPU_IROT-MCTP_VDM-01
# Function to get the enumrated MCTP EID, GPU IRoT I3C
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid EID
get_gpu_irot_mctp_eid_i3c() {
local gpu_irot_i3c_eid="$1"

# default EID to 32, GPU #5 IRoT
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${gpu_irot_i3c_eid:-32} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-GPU_IROT-MCTP_VDM-02
# Function to get the MCTP UUID for GPU IRoT I3C
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_gpu_irot_mctp_uuid_spi() {
local gpu_irot_i3c_eid="$1"

# default EID to 32, GPU #5 IRoT
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${gpu_irot_i3c_eid:-32} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

## GPU: Base Protocol

# HMC-GPU_IROT-PLDM_T0-01
# Function to get PLDM base GetTID of GPU_IROT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_gpu_irot_pldm_tid() {
local gpu_eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${gpu_eid:-32} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-GPU_IROT-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of GPU_IROT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_gpu_irot_pldm_pldmtypes() {
local gpu_eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${gpu_eid:-32} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-GPU_IROT-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of GPU_IROT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_gpu_irot_pldm_t0_pldmversion() {
local gpu_eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${gpu_eid:-32} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-GPU_IROT-PLDM_T0-05
# Function to get PLDM base GetPLDMVersion T5 of GPU_IROT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_gpu_pldm_t5_pldmversion() {
local gpu_eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${gpu_eid:-32} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-GPU-NSM_T0-01
# Function to verify if NSM PING functional via MCTP VDM
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "yes", "no" otherwise
is_gpu_mctp_vdm_nsm_ping_operational() {
local gpu_eid="$1"
local cmd=00

# default EID to 32, GPU #5
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${gpu_eid:-32} && [[ "00" = $(_log_ mctp-pcie-ctrl -s "7e 10 de 80 89 00 $cmd 00" -t 2 -e "${eid}" -i 9 -p 12 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f8) ]] && echo "yes" || echo "no"
}

# HMC-GPU-NSM_T0-02
# Function to verify if NSM PING functional using nsmtool
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "yes", "no" otherwise
is_gpu_mctp_nsmtool_ping_operational() {
local gpu_eid="$1"
local cmd=0x00

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && [[ "00" = $(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '7p') ]] && echo "yes" || echo "no"
}

# HMC-GPU-NSM_T0-03
# Function to verify NSM Get Supported Message Types via MCTP VDM
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "0x3d", fault otherwise
get_gpu_mctp_vdm_nsm_supported_message_types() {
local gpu_eid="$1"
local cmd=01

# default EID to 32, GPU #5
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${gpu_eid:-32} && output=$(_log_ mctp-pcie-ctrl -s "7e 10 de 80 89 00 $cmd 00" -t 2 -e "${eid}" -i 9 -p 12 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f13) && echo "$output"
}

# HMC-GPU-NSM_T0-04
# Function to verify NSM Get Supported Message Types using nsmtool
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "0x3d", fault otherwise
get_gpu_mctp_nsmtool_supported_message_types() {
local gpu_eid="$1"
local cmd=0x01

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12p') && [[ $output ]] && echo "$output" || echo ""
}

## GPU: Firmware Update Protocol

# HMC-GPU_IROT-Version-01
# Function to get GPU IRoT FW version from PLDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid IRoT FW version
get_gpu_irot_fw_version_pldm() {
local eid="$1"
local output
# default EID to 32, GPU #5 IRoT
eid=${eid:-32} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-GPU_IROT-Version-02
# Function to get GPU IRoT FW version from PLDM dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid IRoT FW version
get_gpu_irot_fw_version_pldm_dbus() {
local sw_id="$1"
# default HGX_FW_ERoT_GPU_0
id=${sw_id:-HGX_FW_ERoT_GPU_0} && _log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-GPU_IROT-Version-03
# Function to get GPU IRoT FW Build Type
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid IRoT FW Build Type
get_gpu_irot_fw_build_type() {
local irot_eid="$1"
# default EID to 32, GPU #5 IRoT
# 0: rel, 1: dev
eid=${irot_eid:-32} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build & 0x01) ))

    case "$result" in
        0) echo "rel" ;;
        1) echo "dev" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-GPU_IROT-Version-04
# Function to get GPU IRoT FW Keyset
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid IRoT FW Keyset
get_gpu_irot_fw_keyset() {
local irot_eid="$1"
# default EID to 32, GPU #5 IRoT
# 0: s1, 1: s2, 2: s3, 3: s4, 4: s5
eid=${irot_eid:-32} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 1) & 0x07 ))

    case "$result" in
        0) echo "s1" ;;
        1) echo "s2" ;;
        2) echo "s3" ;;
        3) echo "s4" ;;
        4) echo "s5" ;;
        5) echo "s6" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-GPU_IROT-Version-05
# Function to get GPU IRoT FW Chip Rev
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid IRoT FW Chip Rev
get_gpu_irot_fw_chiprev() {
local irot_eid="$1"
# default EID to 32, GPU #5 IRoT
# 0: revA, 1:revB
eid=${irot_eid:-32} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 4) & 0x03 ))

    case "$result" in
        0) echo "revA" ;;
        1) echo "revB" ;;
        2) echo "revC" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-GPU_IROT-Version-06
# Function to get GPU IRoT FW Boot Slot
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid IRoT FW Boot Slot
get_gpu_irot_fw_boot_slot() {
local irot_eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${irot_eid:-32} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    result=$(( (16#${output[8]} >> 6) & 0x01 ))
    echo "$result"
else
    # Invalid
    echo ""
fi
}

# HMC-GPU_IROT-Version-07
# Function to get GPU IRoT FW EC Identical
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid IRoT FW EC Identical
get_gpu_irot_fw_ec_identical() {
local irot_eid="$1"
# default EID to 32, GPU #5 IRoT
# 0: identical, 1: not identical
eid=${irot_eid:-32} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 7) & 0x01 ))
    if [[ "$result" == "0" ]]; then
        echo "identical"
    elif [[ "$result" == "1" ]]; then
        echo "not identical"
    else
        echo ""
    fi
else
    # Invalid
    echo ""
fi
}

# HMC-GPU_IROT-PLDM_T5-01
# Function to get PLDM fw_update version of GPU_IROT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid IRoT FW version
get_gpu_irot_pldm_version() {
local eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${eid:-32} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-GPU_IROT-PLDM_T5-05
# Function to get PLDM fw_update AP_SKU ID of GPU
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_gpu_irot_pldm_apsku_id() {
local sku_eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${sku_eid:-32} && key=${sku_key:-APSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-GPU_IROT-DBUS-07
# Function to get PLDM DBus software inventory version of GPU iRoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid iRoT FW version
get_dbus_pldm_gpu_irot_version() {
local gpu_pldm_irot_id="$1"
irot_id=${gpu_pldm_irot_id:-HGX_FW_IRoT_GPU_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$irot_id" | grep '.Version' | grep -o '"[^"]*"') && echo $output
}

## GPU: Telemetry Protocol

# HMC-GPU-NSM_T2-01
# Function to query availability of the Simeple Data Sources
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_avil_simple_data_sources() {
local gpu_eid="$1"
local cmd=0x00

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12,27p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-02
# Function to query availability of the Indexed Data Sources
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_avil_indexed_data_sources() {
local gpu_eid="$1"
local cmd=0x01

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12,15p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-03
# Function to query availability of the Bulk Data Sources
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_avil_bulk_data_sources() {
local gpu_eid="$1"
local cmd=0x02

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12,13p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-07
# Function to query maximum PCIe Link Width
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_max_pcie_link_width() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x01 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-08
# Function to query PCIe Link LTSSM State
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid 0x05, L0 state, fault otherwise
get_gpu_mctp_nsmtool_t2_pcie_link_ltssm() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x0e 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-09
# Function to query PCIe Correctable error count
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_pcie_cor_err_count() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x05 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12,13p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-10
# Function to query PCIe Non-Fatal error count
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_pcie_nonfatal_err_count() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x02 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-11
# Function to query PCIe Fatal error count
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_pcie_fatal_err_count() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x03 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-12
# Function to query PCIe L0 to recovery count
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_pcie_l0_recovery_count() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x06 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12,15p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-13
# Function to query PCIe Replay count
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_pcie_replay_count() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x07 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12,15p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-14
# Function to query PCIe Replay Rollover count
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_pcie_replay_rollover_count() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x08 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12,13p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-15
# Function to query PCIe NAKs Sent count
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_pcie_naks_sent_count() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x0a 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12,13p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-16
# Function to query PCIe NAKs Received count
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_pcie_naks_received_count() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x09 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12,13p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}

# HMC-GPU-NSM_T2-17
# Function to query PCIe Unsupported Request count
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid supported data, fault otherwise
get_gpu_mctp_nsmtool_t2_pcie_unsupported_request_count() {
local gpu_eid="$1"
local cmd=0x03

# default EID to 32, GPU #5
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-32} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x02 0x04 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12p' | awk '{printf "0x%s ", $0} END {print ""}') && echo "$output"
}


## Retimer: Firmware Update Protocol

# HMC-Retimer-Version-01
# Function to get Retimer FW version from dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid Retimer FW version
get_retimer_fw_version_dbus() {
local sw_id="$1"
# default to HGX_FW_PCIeRetimer_0
id=${sw_id:-HGX_FW_PCIeRetimer_0} && _log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-Retimer-Version-02
# Function to get Retimer FW version through SMBPBI on I2C-4 bus
# Arguments:
#   $1: I2C Bus number for the BMC I2C-4 (i2c 3)
#   $2: I2C Addr for the FPGA SMBPBI server
#   $3: Register Addr for the target component
# Returns:
#   valid Retimer FW version
get_retimer_fw_version_i2c() {
local i2c_bus="$1"
local i2c_addr="$2"
local register="$3"
local output

# default 3 to i2c bus number, 0x60 to i2c address for the SMBPBI server
# default 0x90 to the register address, Retimer #1
bus=${i2c_bus:-3} && addr=${i2c_addr:-0x60} && reg=${register:-0x90} && output=$(_log_ i2ctransfer -f -y "$bus" w6@"$addr" 0x5c 0x04 0x05 "$reg" 0x00 0x80; i2ctransfer -f -y "$bus" w1@"$addr" 0x5d r5 | cut -d ' ' -f 2-6) && echo "$output"
}

## CX7: Transport Protocol

# HMC-CX7_EROT-MCTP_VDM-01
# Function to get the enumrated MCTP EID, CX7 ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid "17"
get_cx7_erot_mctp_eid_spi() {
local cx7_erot_spi_eid="$1"

# default EID to 17, CX7 MCTP ERoT SPI
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${cx7_erot_spi_eid:-17} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-CX7_EROT-MCTP_VDM-02
# Function to get the enumrated MCTP EID, CX7 ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid "21"
get_cx7_erot_mctp_eid_i2c() {
local cx7_erot_i2c_eid="$1"

# default EID to 21, Umbriel CX7 MCTP ERoT I2C
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${cx7_erot_i2c_eid:-21} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-CX7_EROT-MCTP_VDM-03
# Function to get the MCTP UUID for CX7 ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_cx7_erot_mctp_uuid_spi() {
local cx7_erot_spi_eid="$1"

# default EID to 17, CX7 MCTP ERoT SPI
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${cx7_erot_spi_eid:-17} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

# HMC-CX7_EROT-MCTP_VDM-04
# Function to get the MCTP UUID for CX7 ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_cx7_erot_mctp_uuid_i2c() {
local cx7_erot_i2c_eid="$1"

# default EID to 21, CX7 MCTP ERoT I2C
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${cx7_erot_i2c_eid:-21} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

## CX7: Base Protocol

# HMC-CX7_EROT-PLDM_T0-01
# Function to get PLDM base GetTID of CX7 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_cx7_erot_pldm_tid() {
local cx7_eid="$1"
eid=${cx7_eid:-17} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-CX7_EROT-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of CX7 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_cx7_erot_pldm_pldmtypes() {
local cx7_eid="$1"
eid=${cx7_eid:-17} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-CX7_EROT-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of CX7 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_cx7_erot_pldm_t0_pldmversion() {
local cx7_eid="$1"
eid=${cx7_eid:-17} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-CX7_EROT-PLDM_T0-04
# Function to get PLDM base GetPLDMVersion T5 of CX7 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_cx7_erot_pldm_t5_pldmversion() {
local cx7_eid="$1"
eid=${cx7_eid:-17} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-CX7-PLDM_T0-01
# Function to get PLDM base GetTID of CX7
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_cx7_pldm_tid() {
local cx7_eid="$1"
eid=${cx7_eid:-24} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-CX7-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of CX7
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_cx7_pldm_pldmtypes() {
local cx7_eid="$1"
eid=${cx7_eid:-24} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-CX7-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of CX7
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_cx7_pldm_t0_pldmversion() {
local cx7_eid="$1"
eid=${cx7_eid:-24} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-CX7-PLDM_T0-04
# Function to get PLDM base GetPLDMVersion T2 of CX7
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_cx7_pldm_t2_pldmversion() {
local cx7_eid="$1"
eid=${cx7_eid:-24} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 2 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-CX7-PLDM_T0-05
# Function to get PLDM base GetPLDMVersion T5 of CX7
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_cx7_pldm_t5_pldmversion() {
local cx7_eid="$1"
eid=${cx7_eid:-24} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-CX7-NSM_T0-01
# Function to verify if NSM PING functional via MCTP VDM
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "yes", "no" otherwise
is_cx7_mctp_vdm_nsm_ping_operational() {
local cx7_eid="$1"
local cmd=00

# default EID to 24, CX7 MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${cx7_eid:-24} && [[ "00" = $(_log_ mctp-pcie-ctrl -s "7e 10 de 80 89 00 $cmd 00" -t 2 -e "${eid}" -i 9 -p 12 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f8) ]] && echo "yes" || echo "no"
}

# HMC-CX7-NSM_T0-02
# Function to verify if NSM PING functional using nsmtool
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "yes", "no" otherwise
is_cx7_mctp_nsmtool_ping_operational() {
local cx7_eid="$1"
local cmd=0x00

# default EID to 24, CX7 MCTP EID
# the 'nsmtool' outputs to journal log
eid=${cx7_eid:-24} && [[ "00" = $(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '7p') ]] && echo "yes" || echo "no"
}

# HMC-CX7-NSM_T0-03
# Function to verify NSM Get Supported Message Types via MCTP VDM
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "0x3b", fault otherwise
get_cx7_mctp_vdm_nsm_supported_message_types() {
local cx7_eid="$1"
local cmd=01

# default EID to 24, CX7 MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${cx7_eid:-24} && output=$(_log_ mctp-pcie-ctrl -s "7e 10 de 80 89 00 $cmd 00" -t 2 -e "${eid}" -i 9 -p 12 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f13) && echo "$output"
}

# HMC-CX7-NSM_T0-04
# Function to verify NSM Get Supported Message Types using nsmtool
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "0x3b", fault otherwise
get_cx7_mctp_nsmtool_supported_message_types() {
local gpu_eid="$1"
local cmd=0x01

# default EID to 24, CX7 MCTP EID
# the 'nsmtool' outputs to journal log
eid=${gpu_eid:-24} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12p') && [[ $output ]] && echo "$output" || echo ""
}

## CX7: Firmware Update Protocol

# HMC-CX7_EROT-Version-01
# Function to get CX7 ERoT FW version from PLDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_cx7_erot_fw_version_pldm() {
local eid="$1"
local output
# default EID to 17, CX7 ERoT SPI
eid=${eid:-17} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-CX7_EROT-Version-02
# Function to get CX7 ERoT FW version from PLDM dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid ERoT FW version
get_cx7_erot_fw_version_pldm_dbus() {
local sw_id="$1"
# default HGX_FW_ERoT_PCIeSwitch_0
id=${sw_id:-HGX_FW_ERoT_NVLinkManagementNIC_0} && _log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-CX7_EROT-Version-03
# Function to get CX7 ERoT FW Build Type
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Build Type
get_cx7_erot_fw_build_type() {
local cx7_erot_eid="$1"
# default EID to 17, CX7 ERoT SPI
# 0: rel, 1: dev
eid=${cx7_erot_eid:-17} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build & 0x01) ))

    case "$result" in
        0) echo "rel" ;;
        1) echo "dev" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-CX7_EROT-Version-04
# Function to get CX7 ERoT FW Keyset
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Keyset
get_cx7_erot_fw_keyset() {
local cx7_erot_eid="$1"
# default EID to 17, CX7 ERoT SPI
# 0: s1, 1: s2, 2: s3, 3: s4, 4: s5
eid=${cx7_erot_eid:-17} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 1) & 0x07 ))

    case "$result" in
        0) echo "s1" ;;
        1) echo "s2" ;;
        2) echo "s3" ;;
        3) echo "s4" ;;
        4) echo "s5" ;;
        5) echo "s6" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-CX7_EROT-Version-05
# Function to get CX7 ERoT FW Chip Rev
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Chip Rev
get_cx7_erot_fw_chiprev() {
local cx7_erot_eid="$1"
# default EID to 17, CX7 ERoT SPI
# 0: revA, 1:revB
eid=${cx7_erot_eid:-17} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 4) & 0x03 ))

    case "$result" in
        0) echo "revA" ;;
        1) echo "revB" ;;
        2) echo "revC" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-CX7_EROT-Version-06
# Function to get CX7 ERoT FW Boot Slot
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Boot Slot
get_cx7_erot_fw_boot_slot() {
local cx7_erot_eid="$1"
# default EID to 17, CX7 ERoT SPI
eid=${cx7_erot_eid:-17} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    result=$(( (16#${output[8]} >> 6) & 0x01 ))
    echo "$result"
else
    # Invalid
    echo ""
fi
}

# HMC-CX7_EROT-Version-07
# Function to get CX7 ERoT FW EC Identical
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW EC Identical
get_cx7_erot_fw_ec_identical() {
local cx7_erot_eid="$1"
# default 17 to CX7 ERoT EID
# 0: identical, 1: not identical
eid=${cx7_erot_eid:-17} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 7) & 0x01 ))
    if [[ "$result" == "0" ]]; then
        echo "identical"
    elif [[ "$result" == "1" ]]; then
        echo "not identical"
    else
        echo ""
    fi
else
    # Invalid
    echo ""
fi
}

# HMC-CX7_EROT-PLDM_T5-01
# Function to get PLDM fw_update version of CX7_EROT SPI
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_cx7_erot_pldm_version() {
local eid="$1"
# default EID to 17, CX7 SPI ERoT
eid=${eid:-17} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-CX7_EROT-PLDM_T5-02
# Function to get PLDM fw_update version of CX7
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid FW version
get_cx7_erot_pldm_version_string() {
local eid="$1"
# default EID to 17, CX7 SPI ERoT
eid=${eid:-17} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==2') && echo $output
}

# HMC-CX7_EROT-PLDM_T5-05
# Function to get PLDM fw_update AP_SKU ID of CX7
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_cx7_erot_pldm_apsku_id() {
local sku_eid="$1"
# default EID to 17, CX7 SPI ERoT
eid=${sku_eid:-17} && key=${sku_key:-APSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-CX7_EROT-PLDM_T5-06
# Function to get PLDM fw_update EC_SKU ID of CX7 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_cx7_erot_pldm_ecsku_id() {
local sku_eid="$1"
# default EID to 17, CX7 SPI ERoT
eid=${sku_eid:-17} && key=${sku_key:-ECSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-CX7_EROT-PLDM_T5-07
# Function to get PLDM fw_update GLACIERDSD of CX7 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_cx7_erot_pldm_glacier_id() {
local sku_eid="$1"
# default EID to 17, CX7 SPI ERoT
eid=${sku_eid:-17} && key=${sku_key:-GLACIERDSD} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-CX7_EROT-DBUS-08
# Function to get PLDM DBus software inventory version of CX7 ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid ERoT FW version
get_dbus_pldm_cx7_erot_version() {
local cx7_pldm_erot_id="$1"
erot_id=${cx7_pldm_erot_id:-HGX_FW_ERoT_NVLinkManagementNIC_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$erot_id" | grep '.Version' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

## CX7: Telemetry Protocol

# HMC-CX7-PLDM_T2-02
# Function to disable PLDM T2 sensor polling
# Arguments:
#   n/a
# Returns:
#   valid "done", "failed" otherwise
_disable_cx7_sensor_polling() {
local output
_log_ busctl set-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled b false
output=$(_log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled | grep -o "false"); [[ $output = "false" ]] && echo "done" || echo "failed"
}

# HMC-CX7-PLDM_T2-03
# Function to enable PLDM T2 sensor polling
# Arguments:
#   n/a
# Returns:
#   valid "done", "failed" otherwise
enable_cx7_sensor_polling() {
local output
_log_ busctl set-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled b true
output=$(_log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled | grep -o "true"); [[ $output = "true" ]] && echo "done" || echo "failed"
}

# HMC-CX7-PLDM_T2-04
# Function to dump CX7 PDR in JSON format
# Arguments:
#   CX7 EID
# Returns:
#   valid "done", "failed" otherwise
dump_cx7_pdr_json() {
local cx7_eid="$1"
local jsonfile=/tmp/"$FUNCNAME"_output.json
# default EID to 24, CX7 I2C
eid=${cx7_eid:-24} && logfile=${jsonfile:-"/tmp/func_output.json"} && _log_ pldmtool platform getpdr -m "$eid" -a > "$logfile" && [ $(wc -c < $logfile) -gt 10 ] && : || rm $logfile && [ -f "$logfile" ] && echo "done" || echo "failed"
}

# HMC-CX7-PLDM_T2-05
# Function to get CX7 Numeric Sensor IDs
# Arguments:
#   CX7 EID
# Returns:
#   Numeric Sesnor ID
get_cx7_numeric_sensor_id() {
local cx7_eid="$1"
# default EID to 24, CX7 I2C
eid=${cx7_eid:-24} && output=$(_log_ pldmtool platform getpdr -m "$eid" -a 2>/dev/null | grep -A5 'Numeric Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}'); echo "$output"
}

# HMC-CX7-PLDM_T2-06
# Function to verify if CX7 Numeric Sensor ID is accessible
# Arguments:
#   CX7 EID
# Returns:
#   valid "yes", "no" otherwise
is_cx7_numeric_sensor_accessible() {
    local cx7_eid="$1"
    # default EID to 24, CX7 I2C
    eid=${cx7_eid:-24} && sensor_ids=$(_log_ pldmtool platform getpdr -m "$eid" -a | grep -A5 'Numeric Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}')
    [ -z "$sensor_ids" ] && echo 'no' && return

    # Convert the string into an array
    IFS=' ' read -ra sensor_array <<< "$sensor_ids"

    # Get the last sensord readout
    [[ "00" = $(_log_ pldmtool raw -m "$eid" -v -d 0x80 0x02 0x11 0x$(printf "%x" ${sensor_array[-1]}) 0x00 0x0 0x0 | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '4p') ]] && echo "yes" || echo "no"
}

# HMC-CX7-PLDM_T2-07
# Function to get CX7 State Sensor IDs
# Arguments:
#   CX7 EID
# Returns:
#   Numeric Sesnor ID
get_cx7_state_sensor_id() {
local cx7_eid="$1"
# default EID to 24, CX7 I2C
eid=${cx7_eid:-24} && output=$(_log_ pldmtool platform getpdr -m "$eid" -a 2>/dev/null | grep -A5 'State Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}'); echo "$output"
}

# HMC-CX7-PLDM_T2-08
# Function to verify if all CX7 State Sensor ID is accessible
# Arguments:
#   CX7 EID
# Returns:
#   valid "yes", "no" otherwise
is_cx7_state_sensor_accessible() {
    local cx7_eid="$1"
    # default EID to 24, CX7 I2C
    eid=${cx7_eid:-24} && state_ids=$(_log_ pldmtool platform getpdr -m "$eid" -a | grep -A5 'State Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}')
    [ -z "$state_ids" ] && echo 'no' && return

    # Convert the string into an array
    IFS=' ' read -ra sensor_array <<< "$state_ids"

    # Get the last sensord readout
    [[ "00" = $(_log_ pldmtool raw -m "$eid" -v -d 0x80 0x02 0x21 0x$(printf "%x" ${sensor_array[-1]}) 0x00 0x0 0x0 | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '4p') ]] && echo "yes" || echo "no"
}

## QM3: Transport Protocol

# HMC-QM3_EROT-MCTP_VDM-01
# Function to get the enumrated MCTP EID, QM3 ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid EID
get_qm3_erot_mctp_eid_spi() {
local qm3_erot_spi_eid="$1"

# default EID to 15, QM3 #1 MCTP ERoT SPI
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${qm3_erot_spi_eid:-15} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-QM3_EROT-MCTP_VDM-02
# Function to get the enumrated MCTP EID, QM3 ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid EID
get_qm3_erot_mctp_eid_i2c() {
local qm3_erot_i2c_eid="$1"

# default EID to 19, Umbriel QM3 #1 MCTP ERoT I2C
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${qm3_erot_i2c_eid:-19} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-QM3_EROT-MCTP_VDM-03
# Function to get the MCTP UUID for QM3 ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_qm3_erot_mctp_uuid_spi() {
local qm3_erot_spi_eid="$1"

# default EID to 15, QM3 #1 MCTP ERoT SPI
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${qm3_erot_spi_eid:-15} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

# HMC-QM3_EROT-MCTP_VDM-04
# Function to get the MCTP UUID for QM3 ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_qm3_erot_mctp_uuid_i2c() {
local qm3_erot_i2c_eid="$1"

# default EID to 19, QM3 #1 MCTP ERoT I2C
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${qm3_erot_i2c_eid:-19} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

## QM3: Base Protocol

# HMC-QM3_EROT-PLDM_T0-01
# Function to get PLDM base GetTID of QM3 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_qm3_erot_pldm_tid() {
local qm3_eid="$1"
eid=${qm3_eid:-15} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-QM3_EROT-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of QM3 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_qm3_erot_pldm_pldmtypes() {
local qm3_eid="$1"
eid=${qm3_eid:-15} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-QM3_EROT-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of QM3 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_qm3_erot_pldm_t0_pldmversion() {
local qm3_eid="$1"
eid=${qm3_eid:-15} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-QM3_EROT-PLDM_T0-04
# Function to get PLDM base GetPLDMVersion T5 of QM3 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_qm3_erot_pldm_t5_pldmversion() {
local qm3_eid="$1"
eid=${qm3_eid:-15} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-QM3-PLDM_T0-01
# Function to get PLDM base GetTID of QM3
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_qm3_pldm_tid() {
local qm3_eid="$1"
eid=${qm3_eid:-22} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-QM3-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of QM3
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_qm3_pldm_pldmtypes() {
local qm3_eid="$1"
eid=${qm3_eid:-22} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-QM3-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of QM3
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_qm3_pldm_t0_pldmversion() {
local qm3_eid="$1"
eid=${qm3_eid:-22} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-QM3-PLDM_T0-04
# Function to get PLDM base GetPLDMVersion T2 of QM3
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_qm3_pldm_t2_pldmversion() {
local qm3_eid="$1"
eid=${qm3_eid:-22} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 2 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-QM3-PLDM_T0-05
# Function to get PLDM base GetPLDMVersion T5 of QM3
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_qm3_pldm_t5_pldmversion() {
local qm3_eid="$1"
eid=${qm3_eid:-22} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-QM3-NSM_T0-01
# Function to verify if NSM PING functional via MCTP VDM
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "yes", "no" otherwise
is_qm3_mctp_vdm_nsm_ping_operational() {
local qm3_eid="$1"
local cmd=00

# default EID to 22, QM3 MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${qm3_eid:-22} && [[ "00" = $(_log_ mctp-pcie-ctrl -s "7e 10 de 80 89 00 $cmd 00" -t 2 -e "${eid}" -i 9 -p 12 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f8) ]] && echo "yes" || echo "no"
}

# HMC-QM3-NSM_T0-02
# Function to verify if NSM PING functional using nsmtool
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "yes", "no" otherwise
is_qm3_mctp_nsmtool_ping_operational() {
local qm3_eid="$1"
local cmd=0x00

# default EID to 22, QM3 MCTP EID
# the 'nsmtool' outputs to journal log
eid=${qm3_eid:-22} && [[ "00" = $(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '7p') ]] && echo "yes" || echo "no"
}

# HMC-QM3-NSM_T0-03
# Function to verify NSM Get Supported Message Types via MCTP VDM
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "0x3b", fault otherwise
get_qm3_mctp_vdm_nsm_supported_message_types() {
local qm3_eid="$1"
local cmd=01

# default EID to 22, QM3 MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${cx7_eid:-22} && output=$(_log_ mctp-pcie-ctrl -s "7e 10 de 80 89 00 $cmd 00" -t 2 -e "${eid}" -i 9 -p 12 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f13) && echo "$output"
}

# HMC-QM3-NSM_T0-04
# Function to verify NSM Get Supported Message Types using nsmtool
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "0x3b", fault otherwise
get_qm3_mctp_nsmtool_supported_message_types() {
local qm3_eid="$1"
local cmd=0x01

# default EID to 22, QM3 MCTP EID
# the 'nsmtool' outputs to journal log
eid=${qm3_eid:-22} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12p') && [[ $output ]] && echo "$output" || echo ""
}

## QM3: Firmware Update Protocol

# HMC-QM3_EROT-Version-01
# Function to get QM3 ERoT FW version from PLDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_qm3_erot_fw_version_pldm() {
local eid="$1"
local output
# default EID to 15, QM3 #1 ERoT SPI
eid=${eid:-15} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-QM3_EROT-Version-02
# Function to get QM3 ERoT FW version from PLDM dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid ERoT FW version
get_qm3_erot_fw_version_pldm_dbus() {
local sw_id="$1"
# default HGX_FW_ERoT_QM3_0
id=${sw_id:-HGX_FW_ERoT_NVSwitch_0} && _log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-QM3_EROT-Version-03
# Function to get QM3 ERoT FW Build Type
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Build Type
get_qm3_erot_fw_build_type() {
local qm3_erot_eid="$1"
# default EID to 15, QM3 #1 ERoT SPI
# 0: rel, 1: dev
eid=${qm3_erot_eid:-15} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build & 0x01) ))

    case "$result" in
        0) echo "rel" ;;
        1) echo "dev" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-QM3_EROT-Version-04
# Function to get QM3 ERoT FW Keyset
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Keyset
get_qm3_erot_fw_keyset() {
local qm3_erot_eid="$1"
# default EID to 15, QM3 #1 ERoT SPI
# 0: s1, 1: s2, 2: s3, 3: s4, 4: s5
eid=${qm3_erot_eid:-15} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 1) & 0x07 ))

    case "$result" in
        0) echo "s1" ;;
        1) echo "s2" ;;
        2) echo "s3" ;;
        3) echo "s4" ;;
        4) echo "s5" ;;
        5) echo "s6" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-QM3_EROT-Version-05
# Function to get QM3 ERoT FW Chip Rev
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Chip Rev
get_qm3_erot_fw_chiprev() {
local qm3_erot_eid="$1"
# default EID to 15, QM3 #1 ERoT SPI
# 0: revA, 1:revB
eid=${qm3_erot_eid:-15} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 4) & 0x03 ))

    case "$result" in
        0) echo "revA" ;;
        1) echo "revB" ;;
        2) echo "revC" ;;
        *) echo "" ;;
    esac
else
    # Invalid
    echo ""
fi
}

# HMC-QM3_EROT-Version-06
# Function to get QM3 ERoT FW Boot Slot
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Boot Slot
get_qm3_erot_fw_boot_slot() {
local qm3_erot_eid="$1"
# default EID to 15, QM3 #1 ERoT SPI
eid=${qm3_erot_eid:-17} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    result=$(( (16#${output[8]} >> 6) & 0x01 ))
    echo "$result"
else
    # Invalid
    echo ""
fi
}

# HMC-QM3_EROT-Version-07
# Function to get QM3 ERoT FW EC Identical
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW EC Identical
get_qm3_erot_fw_ec_identical() {
local qm3_erot_eid="$1"
# default EID to 15, QM3 #1 ERoT SPI
# 0: identical, 1: not identical
eid=${qm3_erot_eid:-17} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    exit 1
fi

# completion code="00", successful
if [[ "${output[0]}" == "00" ]]; then
    rev_build=${output[8]}
    result=$(( (16#$rev_build >> 7) & 0x01 ))
    if [[ "$result" == "0" ]]; then
        echo "identical"
    elif [[ "$result" == "1" ]]; then
        echo "not identical"
    else
        echo ""
    fi
else
    # Invalid
    echo ""
fi
}

# HMC-QM3_EROT-PLDM_T5-01
# Function to get PLDM fw_update version of QM3_EROT SPI
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_qm3_erot_pldm_version() {
local eid="$1"
# default EID to 15, QM3 #1 SPI ERoT
eid=${eid:-15} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-QM3_EROT-PLDM_T5-02
# Function to get PLDM fw_update version of QM3
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid FW version
get_qm3_erot_pldm_version_string() {
local eid="$1"
# default EID to 15, QM3 #1 SPI ERoT
eid=${eid:-15} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==2') && echo $output
}

# HMC-QM3_EROT-PLDM_T5-05
# Function to get PLDM fw_update AP_SKU ID of QM3
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_qm3_erot_pldm_apsku_id() {
local sku_eid="$1"
# default EID to 15, QM3 #1 SPI ERoT
eid=${sku_eid:-15} && key=${sku_key:-APSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-QM3_EROT-PLDM_T5-06
# Function to get PLDM fw_update EC_SKU ID of QM3 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_qm3_erot_pldm_ecsku_id() {
local sku_eid="$1"
# default EID to 15, QM3 #1 SPI ERoT
eid=${sku_eid:-15} && key=${sku_key:-ECSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-QM3_EROT-PLDM_T5-07
# Function to get PLDM fw_update GLACIERDSD of QM3 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_qm3_erot_pldm_glacier_id() {
local sku_eid="$1"
# default EID to 15, QM3 #1 SPI ERoT
eid=${sku_eid:-15} && key=${sku_key:-GLACIERDSD} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}
# HMC-QM3_EROT-DBUS-09
# Function to get PLDM DBus software inventory version of QM3 ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid ERoT FW version
get_dbus_pldm_qm3_erot_version() {
local qm3_pldm_erot_id="$1"
erot_id=${qm3_pldm_erot_id:-HGX_FW_ERoT_NVSwitch_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$erot_id" | grep '.Version' | grep -o '"[^"]*"') && echo $output
}

## QM3: Telemetry Protocol

# HMC-QM3-PLDM_T2-02
# Function to disable PLDM T2 sensor polling
# Arguments:
#   n/a
# Returns:
#   valid "done", "failed" otherwise
_disable_qm3_sensor_polling() {
local output
_log_ busctl set-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled b false
output=$(_log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled | grep -o "false"); [[ $output = "false" ]] && echo "done" || echo "failed"
}

# HMC-QM3-PLDM_T2-03
# Function to enable PLDM T2 sensor polling
# Arguments:
#   n/a
# Returns:
#   valid "done", "failed" otherwise
enable_qm3_sensor_polling() {
local output
_log_ busctl set-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled b true
output=$(_log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled | grep -o "true"); [[ $output = "true" ]] && echo "done" || echo "failed"
}

# HMC-QM3-PLDM_T2-04
# Function to dump QM3 PDR in JSON format
# Arguments:
#   QM3 EID
# Returns:
#   valid "done", "failed" otherwise
dump_qm3_pdr_json() {
local qm3_eid="$1"
local jsonfile=/tmp/"$FUNCNAME"_output.json
# default EID to 22, QM3 #1 I2C
eid=${qm3_eid:-22} && logfile=${jsonfile:-"/tmp/func_output.json"} && _log_ pldmtool platform getpdr -m "$eid" -a > "$logfile" && [ $(wc -c < $logfile) -gt 10 ] && : || rm $logfile && [ -f "$logfile" ] && echo "done" || echo "failed"
}

# HMC-QM3-PLDM_T2-05
# Function to get QM3 Numeric Sensor ID
# Arguments:
#   QM3 EID
# Returns:
#   Numeric Sesnor ID
get_qm3_numeric_sensor_id() {
local qm3_eid="$1"
# default EID to 22, QM3 #1 I2C
eid=${qm3_eid:-22} && output=$(_log_ pldmtool platform getpdr -m "$eid" -a 2>/dev/null | grep -A5 'Numeric Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}'); echo "$output"
}

# HMC-QM3-PLDM_T2-06
# Function to verify if QM3 Numeric Sensor ID is accessible
# Arguments:
#   QM3 EID
# Returns:
#   valid "yes", "no" otherwise
is_qm3_numeric_sensor_accessible() {
    local qm3_eid="$1"
    # default EID to 22, QM3 #1 I2C
    eid=${qm3_eid:-22} && sensor_ids=$(_log_ pldmtool platform getpdr -m "$eid" -a | grep -A5 'Numeric Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}')

    # Convert the string into an array
    IFS=' ' read -ra sensor_array <<< "$sensor_ids"

    # Get the last sensord readout
    [[ "00" = $(_log_ pldmtool raw -m "$eid" -v -d 0x80 0x02 0x11 0x$(printf "%x" ${sensor_array[-1]}) 0x00 0x0 0x0 | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '4p') ]] && echo "yes" || echo "no"
}

# HMC-QM3-PLDM_T2-07
# Function to get QM3 State Sensor IDs
# Arguments:
#   QM3 EID
# Returns:
#   Numeric Sesnor ID
get_qm3_state_sensor_id() {
# Todo: filter out only State Sensor ID
local qm3_eid="$1"
# default EID to 22, QM3 #1 I2C
eid=${qm3_eid:-22} && output=$(_log_ pldmtool platform getpdr -m "$eid" -a 2>/dev/null | grep -A5 'State Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}'); echo "$output"
}

# HMC-QM3-PLDM_T2-08
# Function to verify if all QM3 State Sensor ID is accessible
# Arguments:
#   QM3 EID
# Returns:
#   valid "yes", "no" otherwise
is_qm3_state_sensor_accessible() {
    local qm3_eid="$1"
    # default EID to 22, QM3 #1 I2C
    eid=${qm3_eid:-22} && state_ids=$(_log_ pldmtool platform getpdr -m "$eid" -a | grep -A5 'State Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}')

    # Convert the string into an array
    IFS=' ' read -ra sensor_array <<< "$state_ids"

    # Get the last sensord readout
    [[ "00" = $(_log_ pldmtool raw -m "$eid" -v -d 0x80 0x02 0x21 0x$(printf "%x" ${sensor_array[-1]}) 0x00 0x0 0x0 | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '4p') ]] && echo "yes" || echo "no"
}

<<COMMENT
# mctp-vdm-util -h
usage: mctp-vdm-util -t [eid] -c [cmd] [params]
-t/-teid: Endpoint EID
-c/-cmd: Command
Available commands:
        selftest - need 4 bytes as the payload
        boot_complete_v1
        boot_complete_v2_slot_0, boot_complete_v2_slot_1
        set_heartbeat_enable, set_heartbeat_disable
        heartbeat
        query_boot_status -m (more descriptive boot status - not required)
        download_log -f filename(not required)
        restart_notification
        debug_token_install - need 256 bytes debug token
        debug_token_erase
        debug_token_query
        program_certificate_chain - need 2048 bytes certificate
        background_copy_init
        background_copy_disable, background_copy_enable
        background_copy_disable_one, background_copy_enable_one
        background_copy_query_status, background_copy_query_progress
        background_copy_query_pending
        in_band_disable, in_band_enable
        in_band_query_status
        boot_ap
        enable_boot_mode
        disable_boot_mode
        query_boot_mode
        cak_install
        cak_test
        cak_lock
        dot_disable
        dot_token_install
        query_force_grant_revoked_status
        enable_force_grant_revoked, disable_force_grant_revoked
        query_revoke_ap_otp_status
        revoke_ap_otp

mctp-vdm-util -t 24 -c query_boot_status
# mctp-vdm-util -t 13 -c query_boot_status
# teid = 13
# Test command = query_boot_status
# TX: 47 16 00 00 80 01 05 01
# RX: 47 16 00 00 00 01 05 01 00 00 00 01 FD 00 50 11 20
#
# FPGA ERoT EID=13
# TX:
# [47 16 00 00] = "Vendor IANA Number" 4 bytes, 0x1647
# [80] = Rq bit set, Reuqest bit
# [01] = NVIDIA message type
# [05] = Command Code = query boot status
# [01] = NVIDIA message version
# RX:
# [47 16 00 00] = "Vendor IANA Number" 4 bytes, 0x1647
# [00] = Rq bit unset, Response bit
# [01] = NVIDIA message type
# [05] = Command Code = query boot status
# [01] = NVIDIA message version
# [00] = NVIDIA Message Completion Code
# [00 00 01 FD 00 50 11 20] = NVIDIA Message Body = 8 bytes, Response data

# mctp-vdm-util -t 13 -c selftest 0 0 0 0
# teid = 13
# Test command = selftest
# TX: 47 16 00 00 80 01 08 01 00 00 00 00
# RX: 47 16 00 00 00 01 08 01 00 01
#
# TX:
# [00 00 00 00] self-test data => get self-test version
# RX:
# [00] = NVIDIA Message Completion Code
# [01] = self-test version
COMMENT

<<COMMENT
# MCTP VDM, MCTP Architecture and Design Specification
# mctp-pcie-ctrl -hpcie
Various command line options mentioned below
    -v  Verbose level
    -e  Target Endpoint Id
    -i  Own PCI Endpoint Id
    -m  Mode: (0 - Commandline mode, 1 - daemon mode, 2 - SPI test mode)
    -t  Binding Type (0 - Resvd, 1 - I2C, 2 - PCIe, 6 - SPI)
    -b  Binding data (pvt, private)
    -d  Delay in seconds (for MCTP enumeration)
    -s  Tx data (MCTP packet payload: [Req-dgram]-[cmd-code]--)
    -f  Absolute path to configuration json file
    -n  Bus number for the selected interface, eg. PCIe 1, PCIe 2, I2C 3
    -i  pci own eid
    -p  pci bridge eid
    -x  pci bridge pool start eid
To send MCTP message for PCIe binding type

Example:
Sample MCTP Command (Get Routing Table Entries)
mctp-pcie-ctrl -s "00 80 0a 00" -t 2 -b "02 00 00 00 00 01" -e 12 -i 9 -p 12 -x 13 -m 0 -v 1
    - mctp_req_msg  >>  00 80 0A 00
    Byte-16=00h => [16][7]=IC=0b, [16][6:0]=Message Type=0000000b
    Byte-17=80h => [17][7]=Rq=1b, [17][6]=D=0b, [17][5]=Rsvd=0b, [17][4:0]=Instance ID=00000b
    Byte-18=0Ah => [18]=Command Code=0Ah, Get Routing Table Entries
    Byte-19=00h => [19]=Entry Handle (0x00 to access first entries in table)

Sample MCTP Response Message (Get Routing Table Entries)
    - mctp_resp_msg > 00 00 0A 00 01 01 01 0C 80 02 09 02 01 00
    Byte-16=0x0 => [16][7]=IC=0b, [16][6:0]=Message Type=0000000b
    Byte-17=0x0 => [17][7]=Rq=0b=resopnse, [17][6]=D=0b, [17][5]=Rsvd=0b, [17][4:0]=Instance ID=0000b
    Byte-18=0xA => Get Routing Table Entries
    Byte-19=0x0 => SUCCESS

In the case of Broadcast Command, such as Prepare for Endpoint Discovery
mctp-pcie-ctrl -s "00 80 0b" -t 2 -b "03 00 00 00 00 00" -e 255 -i 9 -p 12 -x 13 -m 0 -v 1
-e 255
-s "00 80 0b"
-b "03 00 00 00 00 00"
Private bind data: Routing: 0x03, Remote ID: 0x00

MCTP control messsage completion codes
0x00: SUCCESS
0x01: ERROR, 0x02: ERROR_INVALID_DATA, 0x03: ERROR_INVALID_LENGTH
0x04: ERROR_NOT_READY, 0x05: ERROR_UNSUPPORTED_CMD
0x80-0xFF: COMMAND_SPECIFIC
COMMENT

<<COMMENT
# MCTP NSM, MCTP System Management API
# mctp-pcie-ctrl -hpcie
Various command line options mentioned below
    -v  Verbose level
    -e  Target Endpoint Id
    -i  Own PCI Endpoint Id
    -m  Mode: (0 - Commandline mode, 1 - daemon mode, 2 - SPI test mode)
    -t  Binding Type (0 - Resvd, 1 - I2C, 2 - PCIe, 6 - SPI)
    -b  Binding data (pvt, private)
    -d  Delay in seconds (for MCTP enumeration)
    -s  Tx data (MCTP packet payload: [Req-dgram]-[cmd-code]--)
    -f  Absolute path to configuration json file
    -n  Bus number for the selected interface, eg. PCIe 1, PCIe 2, I2C 3
    -i  pci own eid
    -p  pci bridge eid
    -x  pci bridge pool start eid
To send MCTP message for PCIe binding type

Example: Send NSM PING (0x00) command to FPGA
mctp-pcie-ctrl -s "7e 10 de 80 89 00 00 00" -e 12 -i 9 -t 2 -v 1
    - mctp_req_msg > 10 DE 80 89 00 00 00
      IC/Msg Type: 0x7e, PCI: 10DE, RQ/D/RSV/INSTANCE: 80, OCP Type/Ver: 89
      NV Msg Type: 00, CMD Code: 00, Data Size: 00
    - mctp_resp_msg > 7E 10 DE 00 89 00 00 00 00 00 00 00
      IC/Msg Type: 7E, PCI: 10DE, RQ/D/RSV/INSANCE: 00, OCP Type/Ver: 89
      NV Msg Type: 00, CMD Code: 00, Reason[7:5]/Completion[4:0] Code: 00
      Reserved: 0000 Data Size: 0000

Example: Send NSM Get Supported Message Type (0x01) command to FPGA
mctp-pcie-ctrl -s "7e 10 de 80 89 00 01 00" -e 12 -i 9 -t 2 -v 2
    - mctp_req_msg > 10 DE 80 89 00 01 00
      IC/Msg Type: 0x7e, PCI: 10DE, RQ/D/RSV/INSTANCE: 80, OCP Type/Ver: 89
      NV Msg Type: 00, CMD Code: 01, Data Size: 00
    - mctp_resp_msg > 7E 10 DE 18 89 01 01 01 00 00 00 00
    - mctp_resp_msg > 7E 10 DE 00 89 00 01 00 00 00 20 00 3D 00 00 (x30)
      IC/Msg Type: 7E, PCI: 10DE, RQ/D/RSV/INSANCE: 00, OCP Type/Ver: 89
      NV Msg Type: 0x00, CMD Code: 01, Reason[7:5]/Completion[4:0] Code: 00
      Reserved: 0000 Data Size: 0020, Data: 0x00000000 0x00000000 0x00000000 0x0000003d

Completion Codes
0x00: SUCCESS
0x01: ERROR, 0x02: ERR_INVALID_DATA, 0x03: ERR_INVALID_DATA_LENGTH, 0x04: ERR_NOT_READY
0x05: ERR_UNSUPPORTED_COMMAND_CODE, 0x06: ERR_UNSUPPORTED_MSG_TYPE
0x07 - 0x7E: RESERVED
0x7F: ERR_BUS_ACCESS
0x80 - 0xFF: Command specific
COMMENT

<<COMMENT
# MCTP NSM, MCTP System Management API
# nsmtool -h
NSM requester tool for OpenBMC
Usage: nsmtool [OPTIONS] SUBCOMMAND

Options:
  -h,--help                   Print this help message and exit

Subcommands:
  raw                         send a raw request and print response
  discovery                   Device capability discovery type command
  telemetry                   Network, PCI link and platform telemetry type command
#
Example: Send NSM PING (0x00) command to FPGA
nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 0x00 0x00 -m 12 -v
    - Request nsmtool: <6> Tx: 10 de 80 89 00 00 00
      PCI: 0x10de, RQ/D/RSV/INSTANCE: 0x80, OCP Type/Ver: 0x89
      NV Msg Type: 0x00, CMD Code: 0x00, Data Size: 0x00
    - Response nsmtool: <6> Rx: 10 de 00 89 00 00 00 00 00 00 00
      PCI: 0x10de, RQ/D/RSV/INSANCE: 0x00, OCP Type/Ver: 0x89
      NV Msg Type: 0x00, CMD Code: 0x00, Reason[7:5]/Completion[4:0] Code: 0x00
      Reserved: 0x0000 Data Size: 0x0000
Example: Send NSM Get Supported Message Type (0x01) command to FPGA
nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 0x01 0x00 -m 12 -v
    - Request nsmtool: <6> Tx: 10 de 80 89 00 01 00
      PCI: 0x10de, RQ/D/RSV/INSTANCE: 0x80, OCP Type/Ver: 0x89
      NV Msg Type: 0x00, CMD Code: 0x01, Data Size: 0x00
    - Response nsmtool: <6> Rx: 10 de 00 89 00 01 00 00 00 20 00 3d 00 00(x30)
      PCI: 0x10de, RQ/D/RSV/INSANCE: 0x00, OCP Type/Ver: 0x89
      NV Msg Type: 0x00, CMD Code: 0x01, Reason[7:5]/Completion[4:0] Code: 0x00
      Reserved: 0x0000 Data Size: 0x0020, Data: 0x00000000 0x00000000 0x00000000 0x0000003d

Completion Codes
0x00: SUCCESS
0x01: ERROR, 0x02: ERR_INVALID_DATA, 0x03: ERR_INVALID_DATA_LENGTH, 0x04: ERR_NOT_READY
0x05: ERR_UNSUPPORTED_COMMAND_CODE, 0x06: ERR_UNSUPPORTED_MSG_TYPE
0x07 - 0x7E: RESERVED
0x7F: ERR_BUS_ACCESS
0x80 - 0xFF: Command specific
COMMENT

<<COMMENT
# MCTP NSM, Type 2, PCI Links
nsmtool raw -d 0x10 0xde 0x80 0x89 0x02 $cmd 0x00 -m 12 -v
      NV Msg Type: 0x02, CMD Code: $cmd, Data Size: 0x00
      CMD Code: 0x00, Query availability of simple data sources
      CMD Code: 0x03, Query simple data source
        Arg1, Simple data source tag
        Arg2, Bit 0: 0 - query the value; Bit 0: 1 - query and clear the value
COMMENT

<<COMMENT
pldmtool raw -m $EID -v -d 0x80 <pldmType> <cmdType> <payloadReq>

      0x80 - Rq=1'b, Request Message | D=0'b | rsvd=0'b | Instance ID=00000'b
payloadReq - stream of bytes constructed based on the request message format
             defined for the command type as per the spec.
<cmdType>
Numeric Sensor commands
0x11    GetSensorReading
State Sensor commands
0x21    GetStateSensorReadings

Example: PLDM T2 GetStateSensorReadings
pldmtool raw -m 24 -v -d 0x80 0x02 0x21 0x5 0x00 0x0 0x0
    - Request pldmtool: <6> Tx: 18 01 80 02 21 05 00 00 00
    <pldmType> <cmdType> <payloadReq>
    pldmType: 0x02, cmdType: 0x21, sensorID: 0x0005, sensorRearm: 0x00, reserved: 0x00
    - Response pldmtool: <6> Rx: 00 02 21 00 01 00 01 00 01
    <instanceId> <hdrVersion> <pldmType> <cmdType> <completionCode> <payloadResp>
    pldmType: 0x02, cmdType: 0x21, completionCode: 00, compositeSensorCount: 0x01,
    sensor operational state: 0x00, present state: 0x01, previous state: 0x00, eventState:0x01

Completion Codes
0x00: SUCCESS
0x01: ERROR
0x00: SUCCESS
0x01: ERROR, 0x02: ERROR_INVALID_DATA, 0x03: ERROR_INVALID_LENGTH, 0x04: ERROR_NOT_READY
0x05: ERROR_UNSUPPORTED_PLDM_CMD, 0x20: ERROR_INVALID_PLDM_TYPE
0x80 - 0xFF: Command specific
All other: Reserved
COMMENT


export hmc_checker_version="0.10-05032024"
export -f _log_

display_hmc_checker_version() {
    echo "$hmc_checker_version"
}

_run_all_checks() {
    local output
    while read -r func_line; do
        func_name=$(echo "$func_line" | awk '{print $3}')
        if [ -n "$func_name" ] && [[ "$func_name" != "_"* ]]; then
            export -f "$func_name"
            output=$(timeout 15s bash -c "$func_name")
            # check if running into a timeout (124) or terminate (143) event
            [[ $? -eq 124 || $? -eq 143 ]] && output="execution timeout"
            echo -e "$func_name\e[46G>>>Output>>>  $output"
        fi
    done < <(declare -F | sort -r)
}

skip_keywords=("cx7" "spdm" "gpu" "qm3")
_run_selected_checks() {
    local output
    local skip=false
    while read -r func_line; do
        func_name=$(echo "$func_line" | awk '{print $3}')

        for keyword in "${skip_keywords[@]}"; do
            if [[ "$func_name" == *"$keyword"* ]]; then
                skip=true
                break
            fi
        done

        if [ "$skip" == true ]; then
            skip=false
            continue
        fi

        if [ -n "$func_name" ] && [[ "$func_name" != "_"* ]]; then
            export -f "$func_name"
            output=$(timeout 15s bash -c "$func_name")
            # check if running into a timeout (124) or terminate (143) event
            [[ $? -eq 124 || $? -eq 143 ]] && output="execution timeout"
            echo -e "$func_name\e[46G>>>Output>>>  $output"
        fi
    done < <(declare -F | sort -r)
}

if [ ! $# -eq 0 ]; then
    func_name="$1"
    shift
    # call the function with the provided name along with arguments
    $func_name $@
fi
