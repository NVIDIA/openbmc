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
    elif [ "$1" = "mctp-usb-ctrl" ]; then
        # The 'mctp-usb-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
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

# Glacier EC CRC
_crc8 ()
{
    local crc=0
    local table=( \
        0x00 0x07 0x0e 0x09 0x1c 0x1b 0x12 0x15 0x38 0x3f 0x36 0x31 0x24 0x23 0x2a 0x2d \
        0x70 0x77 0x7e 0x79 0x6c 0x6b 0x62 0x65 0x48 0x4f 0x46 0x41 0x54 0x53 0x5a 0x5d \
        0xe0 0xe7 0xee 0xe9 0xfc 0xfb 0xf2 0xf5 0xd8 0xdf 0xd6 0xd1 0xc4 0xc3 0xca 0xcd \
        0x90 0x97 0x9e 0x99 0x8c 0x8b 0x82 0x85 0xa8 0xaf 0xa6 0xa1 0xb4 0xb3 0xba 0xbd \
        0xc7 0xc0 0xc9 0xce 0xdb 0xdc 0xd5 0xd2 0xff 0xf8 0xf1 0xf6 0xe3 0xe4 0xed 0xea \
        0xb7 0xb0 0xb9 0xbe 0xab 0xac 0xa5 0xa2 0x8f 0x88 0x81 0x86 0x93 0x94 0x9d 0x9a \
        0x27 0x20 0x29 0x2e 0x3b 0x3c 0x35 0x32 0x1f 0x18 0x11 0x16 0x03 0x04 0x0d 0x0a \
        0x57 0x50 0x59 0x5e 0x4b 0x4c 0x45 0x42 0x6f 0x68 0x61 0x66 0x73 0x74 0x7d 0x7a \
        0x89 0x8e 0x87 0x80 0x95 0x92 0x9b 0x9c 0xb1 0xb6 0xbf 0xb8 0xad 0xaa 0xa3 0xa4 \
        0xf9 0xfe 0xf7 0xf0 0xe5 0xe2 0xeb 0xec 0xc1 0xc6 0xcf 0xc8 0xdd 0xda 0xd3 0xd4 \
        0x69 0x6e 0x67 0x60 0x75 0x72 0x7b 0x7c 0x51 0x56 0x5f 0x58 0x4d 0x4a 0x43 0x44 \
        0x19 0x1e 0x17 0x10 0x05 0x02 0x0b 0x0c 0x21 0x26 0x2f 0x28 0x3d 0x3a 0x33 0x34 \
        0x4e 0x49 0x40 0x47 0x52 0x55 0x5c 0x5b 0x76 0x71 0x78 0x7f 0x6a 0x6d 0x64 0x63 \
        0x3e 0x39 0x30 0x37 0x22 0x25 0x2c 0x2b 0x06 0x01 0x08 0x0f 0x1a 0x1d 0x14 0x13 \
        0xae 0xa9 0xa0 0xa7 0xb2 0xb5 0xbc 0xbb 0x96 0x91 0x98 0x9f 0x8a 0x8d 0x84 0x83 \
        0xde 0xd9 0xd0 0xd7 0xc2 0xc5 0xcc 0xcb 0xe6 0xe1 0xe8 0xef 0xfa 0xfd 0xf4 0xf3 )
    for byte in "$@"; do
        idx=$(($crc^$byte))
        crc=${table[$idx]}
    done
    echo $crc
}

_ec_send_message() {
local i2c_bus="${1:-0}"
local i2c_addr="${2:-0x73}"
local i2c_addr_dest="${3:-0x52}"
local i2c_addr_fpga_smbpbi="${4:-0x60}"
local msg_cmd="${5:-0x1d}"
local msg_arg="${6:-0x00}"
local msg_read="${7:-20}"
local output

# FPGA aggregate command to show hidden EC on I2C
_log_ i2cset -y $i2c_bus $i2c_addr_fpga_smbpbi 0xc0 0x01 i

# Prepare and send message
message="0x0f 0x0f 0x01 0x01 0x00 0x00 0xc8 0x7f 0x47 0x16 0x00 0x00 0x81 0x01 $msg_cmd 0x01 $msg_arg"
local i2c_addr_dest_decimal=$(printf "%d" $i2c_addr_dest)
local i2c_8bit=$(( i2c_addr_dest_decimal * 2 ))
arr=($message)
len=$((${#arr[@]}+1))
crc=$(_crc8 $i2c_8bit $message)
ret=$(_log_ i2ctransfer -y $i2c_bus w${len}@${i2c_addr} $message $crc)
sleep 0.5

# Read response
ret=$(_log_ i2ctransfer -y $i2c_bus w1@${i2c_addr} 0x0d "r$msg_read")
[ -z "$ret" ] && echo "" && return
response=($ret)

# Process response
command=${response[15]}
version=${response[16]}
completion=${response[17]}
if (( $command != $msg_cmd || $version != 0x01 || $completion != 0 )); then
output=""
else
output=$ret
fi

# FPGA aggregate command to hide EC
_log_ i2cset -y $i2c_bus $i2c_addr_fpga_smbpbi 0xc0 0x02 i

echo $output
}

# Returns the new MCTP dbus path, or default PCIe path
# Arguments:
#   $1: Dbus name for MCTP control service
# Returns:
#   valid Dbus name, defaulted to PCIe
_get_mctp_dbus_conn() {
    local bus_name="$1"
    dbus_name=${bus_name:-'xyz.openbmc_project.MCTP.Control.PCIe'}
    echo "$dbus_name"
}

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

ip=${bmc_ip:-'192.168.31.2'} && count=${count:-1} && if _log_ ping -c "$count" "$ip" >/dev/null 2>&1; then echo "yes"; else echo "no"; fi
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

# Baseboard-HW-Version-04
# Function to get Platform Product Name from Baseboard FRU through FPGA
# Arguments:
#   $1: HMC I2C bus where the Basebaord FRU resides
#   $2: Basebaord FRU I2C address
# Return:
#   valid Product Name
get_platform_hw_product_name() {
    local i2c_bus="$1"
    local fru_addr="$2"
    local output
    # default i2c_bus to 3 (I2C-4), FRU address to 0x53 (FPGA exposed)
    bus=${i2c_bus:-3} && addr=${fru_addr:-0x53}
    if [[ -f "/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom" ]]; then
        output=$(_log_ dd if=/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom bs=1 skip=147 count=21 | hexdump -v -e '/1 "0x%02X "' | tr -d ' ' | sed 's/0x/\\x/g')
    else
        output=$(_log_ i2ctransfer -f -y "$bus" w1@"$addr" 0x93 r21 | tr -d ' ' | sed 's/0x/\\x/g')
    fi
    if [[ -n "$output" && "$output" != *"\xff"* && "$output" != *"\xFF"* ]]; then printf $output; else echo ""; fi
}

# Baseboard-HW-Version-05
# Function to get Platform Serial Number from Baseboard FRU through FPGA
# Arguments:
#   $1: HMC I2C bus where the Basebaord FRU resides
#   $2: Basebaord FRU I2C address
# Return:
#   valid Part Number
get_platform_hw_serial_number() {
    local i2c_bus="$1"
    local fru_addr="$2"
    local output
    # default i2c_bus to 3 (I2C-4), FRU address to 0x53 (FPGA exposed)
    bus=${i2c_bus:-3} && addr=${fru_addr:-0x53}
    if [[ -f "/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom" ]]; then
        output=$(_log_ dd if=/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom bs=1 skip=191 count=13 | hexdump -v -e '/1 "0x%02X "' | tr -d ' ' | sed 's/0x/\\x/g')
    else
        output=$(_log_ i2ctransfer -f -y "$bus" w1@"$addr" 0xbf r13 | tr -d ' ' | sed 's/0x/\\x/g')
    fi
    if [[ -n "$output" && "$output" != *"\xff"* && "$output" != *"\xFF"* ]]; then printf $output; else echo ""; fi
}

# Baseboard-HW-Version-06
# Function to get Platform Part Number from Baseboard FRU through FPGA
# Arguments:
#   $1: HMC I2C bus where the Basebaord FRU resides
#   $2: Basebaord FRU I2C address
# Return:
#   valid Part Number
get_platform_hw_part_number() {
    local i2c_bus="$1"
    local fru_addr="$2"
    local output
    # default i2c_bus to 3 (I2C-4), FRU address to 0x53 (FPGA exposed)
    bus=${i2c_bus:-3} && addr=${fru_addr:-0x53}
    if [[ -f "/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom" ]]; then
        output=$(_log_ dd if=/sys/bus/i2c/devices/"$bus"-00"${addr#0x}"/eeprom bs=1 skip=169 count=18 | hexdump -v -e '/1 "0x%02X "' | tr -d ' ' | sed 's/0x/\\x/g')
    else
        output=$(_log_ i2ctransfer -f -y "$bus" w1@"$addr" 0xa9 r18 | tr -d ' ' | sed 's/0x/\\x/g')
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

# HMC-HMC-Service-08
# Function to verify if the HMC MCTP USB service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_mctp_usb_ctrl_service_active() {
local service_name="$1"
local output
name=${service_name:-'mctp-usb-ctrl.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC-Service-09
# Function to verify if the MCTP USB service is active
# Arguments:
#   $1: Service name
# Returns:
#   valid "yes", "no" otherwise
is_hmc_mctp_usb_demux_service_active() {
local service_name="$1"
local output
name=${service_name:-'mctp-usb-demux.service'} && output=$(_log_ systemctl is-active "$name"); [[ "$output" = 'active' ]] && echo "yes" || echo "no"
}

# HMC-HMC-DBUS-01
# Function to get MCTP DBus VDM tree EIDs
# Arguments:
#   $1: MCTP dbus service name
# Returns:
#   flattened list of the MCTP VDM tree EIDs
get_hmc_dbus_mctp_vdm_tree_eids() {
local dbus_name=$(_get_mctp_dbus_conn "$1")
output=$(_log_ busctl tree "$dbus_name" | grep -o '/0/[0-9]\+$' | sed 's/\/0\///') && echo $output
}

# HMC-HMC-DBUS-11
# Function to get MCTP DBus SPI tree EIDs
# Arguments:
#   n/a
# Returns:
#   flattened list of the MCTP SPI tree EIDs
get_hmc_dbus_mctp_spi_tree_eids() {
local dbus_name="$1"
name=${dbus_name:-'xyz.openbmc_project.MCTP.Control.SPI'} && output=$(_log_ busctl tree "$name" | grep -o '/0/[0-9]\+$' | sed 's/\/0\///') && echo $output
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
local dbus_name="$2"
local output

# default EID to 0, HMC ERoT via MCTP over SPI
name=${dbus_name:-'xyz.openbmc_project.MCTP.Control.SPI'} && erot_id=${eid:-0} && output=$(_log_ busctl introspect "${name}" /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

# HMC-HMC_EROT-DBUS-13
# Function to get HMC ERoT-SPI MCTP UUID via MCTP over VDM through DBus
# Arguments:
#   $1: MCTP EID
#   $2: MCTP dbus service name
# Returns:
#   valid MCTP UUID
get_hmc_dbus_mctp_vdm_spi_uuid() {
local eid="$1"
local dbus_name=$(_get_mctp_dbus_conn "$2")
local output

# default EID to 14, HMC ERoT via MCTP over VDM
erot_id=${eid:-14} && output=$(_log_ busctl introspect "$dbus_name" /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

# HMC-HMC_EROT-DBUS-14
# Function to get HMC ERoT-I2C MCTP UUID via MCTP over VDM through DBus
# Arguments:
#   $1: MCTP EID
#   $2: MCTP dbus service name
# Returns:
#   valid MCTP UUID
get_hmc_dbus_mctp_vdm_i2c_uuid() {
local eid="$1"
local dbus_name=$(_get_mctp_dbus_conn "$2")
local output

# default EID to 18, HMC ERoT via MCTP over VDM
erot_id=${eid:-18} && output=$(_log_ busctl introspect "$dbus_name" /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
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

# HMC-HMC-Version-03
# Function to get HMC FW platform build type
# Arguments:
#   $1: Full version string or not
# Returns:
#   valid HMC FW version
get_hmc_fw_build_type() {
local full_str="$1"
# default false to full_str
type=$(_log_ cat /etc/os-release | grep ^BUILD_DESC | cut -d '=' -f 2 | tr -d '"') && echo $type
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
    return 1
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
# 0: s1, 1: s2, 2: s3, 3: s4, 4: s5, 5: s6
eid=${hmc_erot_eid:-14} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
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
    return 1
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
    return 1
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
    return 1
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

# HMC-HMC_EROT-PLDM_T5-08
# Function to get PLDM fw_update PCI Vendor ID of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Vendor" ID
get_hmc_erot_pldm_pci_vendor_id() {
local sku_eid="$1"
# default EID to 14, HMC ERoT
eid=${sku_eid:-14} && key=${sku_key:-"PCI Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-HMC_EROT-PLDM_T5-09
# Function to get PLDM fw_update PCI Deivce ID of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Device" ID
get_hmc_erot_pldm_pci_device_id() {
local sku_eid="$1"
# default EID to 14, HMC ERoT
eid=${sku_eid:-14} && key=${sku_key:-"PCI Device ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-HMC_EROT-PLDM_T5-10
# Function to get PLDM fw_update PCI Subsystem Vendor ID of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem Vendor" ID
get_hmc_erot_pldm_pci_subsys_vendor_id() {
local sku_eid="$1"
# default EID to 14, HMC ERoT
eid=${sku_eid:-14} && key=${sku_key:-"PCI Subsystem Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-HMC_EROT-PLDM_T5-11
# Function to get PLDM fw_update PCI Subsystem ID of HMC ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem" ID
get_hmc_erot_pldm_pci_subsys_id() {
local sku_eid="$1"
# default EID to 14, HMC ERoT
eid=${sku_eid:-14} && key=${sku_key:-"PCI Subsystem ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
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
local hmc_pldm_erot_id="$1"
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

# HMC-HMC_EROT-Key-01
# Function to get EC key revoke policy via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid revoke policy
get_hmc_erot_key_revoke_policy_i2c() {
local i2c_addr="${1:-0x73}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke policy", cmd=0x1d, arg=0x00, read length=20
response=$(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x1d 0x00 20)

output=${response:90:4}

case $output in
0x00) echo "not set";;
0x01) echo "auto";;
0x02) echo "decoupled";;
*) echo "unknown";;
esac
}

# HMC-HMC_EROT-Key-02
# Function to get EC key revoke policy via VDM
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid revoke policy
get_hmc_erot_key_revoke_policy_vdm() {
local hmc_erot_spi_eid="$1"

# default EID to 14, HMC MCTP ERoT SPI
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${hmc_erot_spi_eid:-14} && output=$(_log_ mctp-pcie-ctrl -s "7f 00 00 16 47 80 01 1d 01 00" -t 2 -e "${eid}" -i 9 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 11)

case $output in
00) echo "not set";;
01) echo "auto";;
02) echo "decoupled";;
*) echo "unknown";;
esac
}

# HMC-HMC_EROT-Key-03
# Function to get EC key revoke state via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid EC key revoke state
get_hmc_erot_ec_key_revoke_state_i2c() {
local i2c_addr="${1:-0x73}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke", selftest cmd=0x08, arg=0x08, read length=61
response=($(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x08 0x08 61))

# EC Key Revoke state
echo ${response[35]}
}

# HMC-HMC_EROT-Key-04
# Function to get EC key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_hmc_erot_ec_key_revoke_state_vdm() {
local hmc_erot_eid="$1"
local eid
local response
local output
# default 14 to HMC ERoT EID
eid=${hmc_erot_eid:-14} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[18]}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-HMC_EROT-Key-05
# Function to get AP key revoke state via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid EC key revoke state
get_hmc_erot_ap_key_revoke_state_i2c() {
local i2c_addr="${1:-0x73}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke", selftest cmd=0x08, arg=0x08, read length=61
response=($(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x08 0x08 61))

# AP Key Revoke state
output=${response[@]:52:8}
echo $output
}

# HMC-HMC_EROT-Key-06
# Function to get AP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_hmc_erot_ap_key_revoke_state_vdm() {
local hmc_erot_eid="$1"
local eid
local response
local output
# default 14 to HMC ERoT EID
eid=${hmc_erot_eid:-14} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:35:8}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-HMC_EROT-Key-07
# Function to get EC RBP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC RBP key revoke state
get_hmc_erot_ec_rbp_key_revoke_state_vdm() {
local hmc_erot_eid="$1"
local eid
local response
local output
# default 14 to HMC ERoT EID
eid=${hmc_erot_eid:-14} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:2:16}
else
    # Invalid
    output=""
fi

# EC RBP Key Revoke state
echo $output
}

# HMC-HMC_EROT-Key-08
# Function to get AP RBP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP RBP key revoke state
get_hmc_erot_ap_rbp_key_revoke_state_vdm() {
local hmc_erot_eid="$1"
local eid
local response
local output
# default 14 to HMC ERoT EID
eid=${hmc_erot_eid:-14} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:19:16}
else
    # Invalid
    output=""
fi

# AP RBP Key Revoke state
echo $output
}

# HMC-HMC_EROT-Security-01
# Function to get EC background copy progress state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC background copy progress state
get_hmc_erot_background_copy_progress_state_vdm() {
local hmc_erot_eid="$1"
local eid
local response
local output
# default 14 to HMC ERoT EID
eid=${hmc_erot_eid:-14} && response=($(_log_ mctp-vdm-util -t ${eid} -c background_copy_query_progress | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-11))

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[1]}
else
    # Invalid
    output=""
fi

case $output in
01) echo "copy not in progress";;
02) echo "copy in progress";;
*) echo "unknown";;
esac
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

# HMC-HMC_EROT-SPDM-12
# Function to get SPDM NVDA Certificate count using spdmtool
# Arguments:
#   $1: EID
#   $2: Slot ID
# Returns:
#   valid SPDM Certificate count
get_hmc_erot_spdm_certificate_count_spdmtool_nvda() {
local input_eid="$1"
local slot_id="$2"
# default EID to 14, HMC ERoT; slot to 0, NVDA cert chain
eid=${input_eid:-14} && slot=${slot_id:-0} && count=$(_log_ spdmtool -e ${eid} get-cert --slot ${slot} | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $count
}

# HMC-HMC_EROT-SPDM-13
# Function to get SPDM MCHP Certificate count using spdmtool
# Arguments:
#   $1: EID
#   $2: Slot ID
# Returns:
#   valid SPDM Certificate count
get_hmc_erot_spdm_certificate_count_spdmtool_mchp() {
local input_eid="$1"
local slot_id="$2"
# default EID to 14, HMC ERoT; slot to 1, MCHP cert chain
eid=${input_eid:-14} && slot=${slot_id:-1} && count=$(_log_ spdmtool -e ${eid} get-cert --slot ${slot} | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $count
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
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local pwr_gd_offset="${4:-0x36}"
# bit mask for the bit 0
local mask="${5:-1}"
if [ "$bytes_to_write" = 2 ] ;
then
    # default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
    out=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x77 0x00 r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
else
    out=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" "$pwr_gd_offset" r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
fi
}

# HMC-FPGA-GPIO-02
# Function to verify GPIO Input of FPGA_MIDP_HGX_FPGA_READY through register table
# Arguments:
#   n/a
# Returns:
#   set "yes", "no" otherwise
is_fpga_midp_hgx_fpga_ready_set_regtable() {
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local ready_offset="${4:-0x36}"
# bit mask for the bit 1
local mask="${5:-2}"
if [ "$bytes_to_write" = 2 ] ;
then
    # default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
    out=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x77 0x00 r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
else
    out=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" "$ready_offset" r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
fi
}

# HMC-FPGA-GPIO-03
# Function to verify GPIO Input of FPGA_MIDP_THERM_OVERT_L through register table
# Arguments:
#   n/a
# Returns:
#   set "yes", "no" otherwise
is_fpga_midp_therm_overt_not_set_regtable() {
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local therm_overt_offset="${4:-0x36}"
# bit mask for the bit 2
local mask="${5:-4}"
if [ "$bytes_to_write" = 2 ] ;
then
    # default 2 to i2c bus number, 0x0b to i2c address for the FPGA register table (read-only)
    out=$(_log_ i2ctransfer -y "$i2c_bus" w2@"$i2c_addr" 0x77 0x00 r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
else
    out=$(_log_ i2ctransfer -y "$i2c_bus" w1@"$i2c_addr" "$therm_overt_offset" r1) && (( 16#${out#0x} & $mask )) && echo "yes" || echo "no"
fi
}

# HMC-FPGA-GPIO-04
# Function to verify GPIO Input of FPGA_HMC_I2C3_ALERT_L through register table
# Arguments:
#   n/a
# Returns:
#   set "yes", "no" otherwise
is_fpga_hmc_i2c3_alert_not_set_regtable() {
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local hmcsts_reg="${4:-0x36}"
# bit mask for the bit 5
local mask="${5:-32}"
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
local i2c_bus="${1:-2}"
local i2c_addr="${2:-0x0b}"
local bytes_to_write="${3:-1}"
local hmcsts_reg="${4:-0x36}"
# bit mask for the bit 6
local mask="${5:-64}"
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
#   $1: FPGA_READY GPIO
# Returns:
#   set "yes", "no" otherwise
is_fpga_gpio_fpga_ready_set() {
    # The nvidia-fpga-ready-monitor.service utilizes the fpga_ready GPI.
    # Stop the service before making attempt to access the fpga_ready GPI.
    local fpga_gpi="$1"
    fpga_ready=${fpga_gpi:-"fpga_ready"}
    systemctl stop nvidia-fpga-ready-monitor.service >/dev/null 2>&1
    sleep 1
    output=$(_log_ gpioget `gpiofind "$fpga_ready"`); [ "$output" = "1" ] && echo "yes" || echo "no"
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
# Function to get FPGA version through VFIO SMBPBI Proxy via GPU Manager
# Arguments:
#   $1: GPU Manager Object ID
# Returns:
#   valid FPGA version
get_fpga_version_vfio_smbpbi_proxy_gpumgr() {
# default to HGX_FW_FPGA_0
sw_id="$1"
id=${sw_id:-HGX_FW_FPGA_0} && _log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-FPGA-VFIO_SMBPBI-02
# Function to get FPGA PCIe Power State through VFIO SMBPBI Proxy via GPU Manager
# Arguments:
#   $1: System ID
# Returns:
#   valid "On" state
get_fpga_pcie_power_state_vfio_smbpbi_proxy_gpumgr() {
local system_id="$1"
# default to PCIeToHMC_0
id=${system_id:-PCIeToHMC_0} && output=$(_log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/inventory/system/processors/FPGA_0/Ports/"${id}" xyz.openbmc_project.State.Chassis CurrentPowerState | cut -d ' ' -f 2 | tr -d '"' | cut -d '.' -f 6) && echo $output
}

# HMC-FPGA-VFIO_SMBPBI-03
# Function to get FPGA temperature through VFIO SMBPBI Proxy via GPU Manager
# Arguments:
#   $1: callback ID
# Returns:
#   valid FPGA temperature
get_fpga_temperature_vfio_smbpbi_proxy_gpumgr() {
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
# regular out 0x5d: Bit[15:0] Major version, Bit[31:16] Minvor version
# extended out 0x5e: Bit 31:0 build number
bus=${i2c_bus:-3} && addr=${i2c_addr:-0x60} && reg=${register:-0x90} && output=$(_log_ i2ctransfer -f -y "$bus" w6@"$addr" 0x5c 0x04 0x05 "$reg" 0x00 0x80; i2ctransfer -f -y "$bus" w1@"$addr" 0x5d r5 | cut -d ' ' -f 2-6) && output="$output $(i2ctransfer -f -y "$bus" w1@"$addr" 0x5e r5 | cut -d ' ' -f 2-6)" && echo "$output"
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
#   $1: MCTP dbus service name 
# Returns:
#   flattened list of the MCTP tree EIDs
get_hmc_mctp_eids_tree() {
local dbus_name=$(_get_mctp_dbus_conn "$1")
output=$(_log_ busctl tree "$dbus_name"  | grep -o '/0/[0-9]\+$' | sed 's/\/0\///') && echo $output
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
    return 1
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
    return 1
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
    return 1
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
    return 1
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
    return 1
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

# HMC-FPGA_EROT-PLDM_T5-08
# Function to get PLDM fw_update PCI Vendor ID of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Vendor" ID
get_fpga_erot_pldm_pci_vendor_id() {
local sku_eid="$1"
# default EID to 13, FPGA ERoT
eid=${sku_eid:-13} && key=${sku_key:-"PCI Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-FPGA_EROT-PLDM_T5-09
# Function to get PLDM fw_update PCI Deivce ID of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Device" ID
get_fpga_erot_pldm_pci_device_id() {
local sku_eid="$1"
# default EID to 13, FPGA ERoT
eid=${sku_eid:-13} && key=${sku_key:-"PCI Device ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-FPGA_EROT-PLDM_T5-10
# Function to get PLDM fw_update PCI Subsystem Vendor ID of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem Vendor" ID
get_fpga_erot_pldm_pci_subsys_vendor_id() {
local sku_eid="$1"
# default EID to 13, FPGA ERoT
eid=${sku_eid:-13} && key=${sku_key:-"PCI Subsystem Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-FPGA_EROT-PLDM_T5-11
# Function to get PLDM fw_update PCI Subsystem ID of FPGA ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem" ID
get_fpga_erot_pldm_pci_subsys_id() {
local sku_eid="$1"
# default EID to 13, FPGA ERoT
eid=${sku_eid:-13} && key=${sku_key:-"PCI Subsystem ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
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
erot_id=${hmc_pldm_erot_id:-HGX_FW_ERoT_BMC_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$erot_id" | grep '^\.Version' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

# HMC-FPGA_EROT-DBUS-06
# Function to get PLDM DBus software inventory version of FPGA ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid ERoT FW version
get_hmc_dbus_pldm_fpga_erot_version() {
local fpga_pldm_erot_id="$1"
erot_id=${fpga_pldm_erot_id:-HGX_FW_ERoT_FPGA_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$erot_id" | grep '^\.Version' | grep -o '"[^"]*"' | tr -d '"') && echo $output
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

# HMC-FPGA_EROT-Key-01
# Function to get EC key revoke policy via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid revoke policy
get_fpga_erot_key_revoke_policy_i2c() {
local i2c_addr="${1:-0x52}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke policy", cmd=0x1d, arg=0x00, read length=20
response=$(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x1d 0x00 20)

output=${response:90:4}

case $output in
0x00) echo "not set";;
0x01) echo "auto";;
0x02) echo "decoupled";;
*) echo "unknown";;
esac
}

# HMC-FPGA_EROT-Key-02
# Function to get EC key revoke policy via VDM
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid revoke policy
get_fpga_erot_key_revoke_policy_vdm() {
local fpga_erot_spi_eid="$1"

# default EID to 13, FPGA MCTP ERoT SPI
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${fpga_erot_spi_eid:-13} && output=$(_log_ mctp-pcie-ctrl -s "7f 00 00 16 47 80 01 1d 01 00" -t 2 -e "${eid}" -i 9 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 11)

case $output in
00) echo "not set";;
01) echo "auto";;
02) echo "decoupled";;
*) echo "unknown";;
esac
}

# HMC-FPGA_EROT-Key-03
# Function to get EC key revoke state via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid EC key revoke state
get_fpga_erot_ec_key_revoke_state_i2c() {
local i2c_addr="${1:-0x52}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke", selftest cmd=0x08, arg=0x08, read length=61
response=($(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x08 0x08 61))

# EC Key Revoke state
echo ${response[35]}
}

# HMC-FPGA_EROT-Key-04
# Function to get EC key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_fpga_erot_ec_key_revoke_state_vdm() {
local fpga_erot_eid="$1"
local eid
local response
local output
# default 13 to FPGA ERoT EID
eid=${fpga_erot_eid:-13} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[18]}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-FPGA_EROT-Key-05
# Function to get AP key revoke state via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid EC key revoke state
get_fpga_erot_ap_key_revoke_state_i2c() {
local i2c_addr="${1:-0x52}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke", selftest cmd=0x08, arg=0x08, read length=61
response=($(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x08 0x08 61))

# AP Key Revoke state
output=${response[@]:52:8}
echo $output
}

# HMC-FPGA_EROT-Key-06
# Function to get AP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_fpga_erot_ap_key_revoke_state_vdm() {
local fpga_erot_eid="$1"
local eid
local response
local output
# default 13 to FPGA ERoT EID
eid=${fpga_erot_eid:-13} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:35:8}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-FPGA_EROT-Key-07
# Function to get EC RBP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC RBP key revoke state
get_fpga_erot_ec_rbp_key_revoke_state_vdm() {
local fpga_erot_eid="$1"
local eid
local response
local output
# default 13 to FPGA ERoT EID
eid=${fpga_erot_eid:-13} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:2:16}
else
    # Invalid
    output=""
fi

# EC RBP Key Revoke state
echo $output
}

# HMC-FPGA_EROT-Key-08
# Function to get AP RBP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP RBP key revoke state
get_fpga_erot_ap_rbp_key_revoke_state_vdm() {
local fpga_erot_eid="$1"
local eid
local response
local output
# default 13 to FPGA ERoT EID
eid=${fpga_erot_eid:-13} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:19:16}
else
    # Invalid
    output=""
fi

# AP RBP Key Revoke state
echo $output
}

# HMC-FPGA_EROT-Security-01
# Function to get EC background copy progress state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC background copy progress state
get_fpga_erot_background_copy_progress_state_vdm() {
local fpga_erot_eid="$1"
local eid
local response
local output
# default 13 to FPGA ERoT EID
eid=${fpga_erot_eid:-13} && response=($(_log_ mctp-vdm-util -t ${eid} -c background_copy_query_progress | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-11))

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[1]}
else
    # Invalid
    output=""
fi

case $output in
01) echo "copy not in progress";;
02) echo "copy in progress";;
*) echo "unknown";;
esac
}

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

# HMC-FPGA_EROT-SPDM-07
# Function to get SPDM NVDA Certificate count using spdmtool
# Arguments:
#   $1: EID
#   $2: Slot ID
# Returns:
#   valid SPDM Certificate count
get_fpga_erot_spdm_certificate_count_spdmtool_nvda() {
local input_eid="$1"
local slot_id="$2"
# default EID to 13, FPGA ERoT; slot to 0, NVDA cert chain
eid=${input_eid:-13} && slot=${slot_id:-0} && count=$(_log_ spdmtool -e ${eid} get-cert --slot ${slot} | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $count
}

# HMC-FPGA_EROT-SPDM-08
# Function to get SPDM MCHP Certificate count using spdmtool
# Arguments:
#   $1: EID
#   $2: Slot ID
# Returns:
#   valid SPDM Certificate count
get_fpga_erot_spdm_certificate_count_spdmtool_mchp() {
local input_eid="$1"
local slot_id="$2"
# default EID to 13, FPGA ERoT; slot to 1, MCHP cert chain
eid=${input_eid:-13} && slot=${slot_id:-1} && count=$(_log_ spdmtool -e ${eid} get-cert --slot ${slot} | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $count
}

## GPU: Transport Protocol

# HMC-GPU-VFIO_SMBPBI-01
# Function to get GPU FW version through VFIO SMBPBI Proxy via GPU Manager
# Arguments:
#   $1: Software ID
# Returns:
#   valid GPU version
get_gpu_version_vfio_smbpbi_proxy_gpumgr() {
local sw_id="$1"
# default to HGX_FW_GPU_SXM5
id=${sw_id:-HGX_FW_GPU_SXM5} && _log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-GPU-VFIO_SMBPBI-02
# Function to get GPU PCIe lane in use through VFIO SMBPBI Proxy via GPU Manager
# Arguments:
#   $1: Chassis ID
# Returns:
#   valid lane/width number
get_gpu_pcie_width_vfio_smbpbi_proxy_gpumgr() {
local chassis_id="$1"
# default to GPU_SXM_5
id=${chassis_id:-GPU_SXM_5} && output=$(_log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/inventory/system/chassis/HGX_$id/PCIeDevices/$id xyz.openbmc_project.Inventory.Item.PCIeDevice LanesInUse | cut -d ' ' -f 2 | tr -d '"') && echo $output
}

# HMC-GPU-VFIO_SMBPBI-03
# Function to get GPU temperature through VFIO SMBPBI Proxy via GPU Manager
# Arguments:
#   $1: callback ID
# Returns:
#   valid GPU temperature
get_gpu_temperature_vfio_smbpbi_proxy_gpumgr() {
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

# HMC-GPU_EROT-MCTP_VDM-02
# Function to get the enumrated MCTP EID, GPU ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid "26"
get_gpu_erot_mctp_eid_i2c() {
local gpu_erot_i2c_eid="$1"

# default EID to 18, Nero GPU MCTP ERoT I2C
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${gpu_erot_i2c_eid:-26} && mctp_call='_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1' && eid_rt=$(eval " $mctp_call" 2>&1 | grep mctp_resp_msg | cut -d ' ' -f 8) && printf '%d\n' 0x$eid_rt
}

# HMC-GPU_EROT-MCTP_VDM-04
# Function to get the MCTP UUID for GPU ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_gpu_erot_mctp_uuid_i2c() {
local gpu_erot_i2c_eid="$1"

# default EID to 26, GPU MCTP ERoT I2C
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${gpu_erot_i2c_eid:-26} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

# HMC-GPU_EROT-DBUS-14
# Function to get GPU ERoT-I2C MCTP UUID via MCTP over VDM through DBus
# Arguments:
#   $1: MCTP EID
#   $2: MCTP dbus service name
# Returns:
#   valid MCTP UUID
get_gpu_dbus_mctp_vdm_i2c_uuid() {
local eid="$1"
local dbus_name=$(_get_mctp_dbus_conn "$2")
local output

# default EID to 26, GPU ERoT via MCTP over VDM
erot_id=${eid:-26} && output=$(_log_ busctl introspect "$dbus_name" /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

## GPU: Base Protocol

# HMC-GPU_EROT-PLDM_T0-01
# Function to get PLDM base GetTID of GPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_gpu_erot_pldm_tid() {
local gpu_eid="$1"
eid=${gpu_eid:-26} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-GPU_EROT-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of GPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_gpu_erot_pldm_pldmtypes() {
local gpu_eid="$1"
eid=${gpu_eid:-26} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-GPU_EROT-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of GPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_gpu_erot_pldm_t0_pldmversion() {
local gpu_eid="$1"
eid=${gpu_eid:-26} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-GPU_EROT-PLDM_T0-04
# Function to get PLDM base GetPLDMVersion T5 of GPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_gpu_erot_pldm_t5_pldmversion() {
local gpu_eid="$1"
eid=${gpu_eid:-26} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

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

# HMC-GPU_EROT-Version-01
# Function to get GPU ERoT FW version from PLDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_gpu_erot_fw_version_pldm() {
local eid="$1"
local output
# default EID to 14, GPU ERoT
eid=${eid:-26} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-GPU_EROT-Version-02
# Function to get GPU ERoT FW version from PLDM dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid ERoT FW version
get_gpu_erot_fw_version_pldm_dbus() {
local sw_id="$1"
id=${sw_id:-HGX_FW_ERoT_GPU_SXM_1} && _log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-GPU_EROT-Version-03
# Function to get GPU ERoT FW Build Type
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Build Type
get_gpu_erot_fw_build_type() {
local gpu_erot_eid="$1"
# default 26 to GPU ERoT EID
# 0: rel, 1: dev
eid=${gpu_erot_eid:-26} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

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

# HMC-GPU_EROT-Version-04
# Function to get GPU ERoT FW Keyset
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Keyset
get_gpu_erot_fw_keyset() {
local gpu_erot_eid="$1"
# default 26 to GPU ERoT EID
# 0: s1, 1: s2, 2: s3, 3: s4, 4: s5
eid=${gpu_erot_eid:-26} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

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

# HMC-GPU_EROT-Version-05
# Function to get GPU ERoT FW Chip Rev
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Chip Rev
get_gpu_erot_fw_chiprev() {
local gpu_erot_eid="$1"
# default 26 to GPU ERoT EID
# 0: revA, 1:revB
eid=${gpu_erot_eid:-26} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

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

# HMC-GPU_EROT-Version-06
# Function to get GPU ERoT FW Boot Slot
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Boot Slot
get_gpu_erot_fw_boot_slot() {
local gpu_erot_eid="$1"
# default 26 to GPU ERoT EID
eid=${gpu_erot_eid:-26} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

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

# HMC-GPU_EROT-Version-07
# Function to get GPU ERoT FW EC Identical
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW EC Identical
get_gpu_erot_fw_ec_identical() {
local gpu_erot_eid="$1"
# default 26 to GPU ERoT EID
# 0: identical, 1: not identical
eid=${gpu_erot_eid:-26} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

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

# HMC-GPU_EROT-PLDM_T5-02
# Function to get PLDM fw_update version of GPU
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid FW version
get_gpu_erot_pldm_version_string() {
local eid="$1"
# default EID to 26, GPU ERoT
eid=${eid:-26} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==2') && echo $output
}

# HMC-GPU_EROT-PLDM_T5-05
# Function to get PLDM fw_update AP_SKU ID of GPU
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_gpu_erot_pldm_apsku_id() {
local sku_eid="$1"
# default EID to 26, GPU ERoT
eid=${sku_eid:-26} && key=${sku_key:-APSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-GPU_EROT-PLDM_T5-06
# Function to get PLDM fw_update EC_SKU ID of GPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC_SKU ID
get_gpu_erot_pldm_ecsku_id() {
local sku_eid="$1"
# default EID to 26, GPU ERoT
eid=${sku_eid:-26} && key=${sku_key:-ECSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-GPU_EROT-PLDM_T5-07
# Function to get PLDM fw_update GLACIERDSD of GPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid GLACIERDSD ID
get_gpu_erot_pldm_glacier_id() {
local sku_eid="$1"
# default EID to 26, GPU ERoT
eid=${sku_eid:-26} && key=${sku_key:-GLACIERDSD} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-GPU_EROT-DBUS-03
# Function to get PLDM DBus chassis inventory UUID of GPU ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid MCTP UUID
get_gpu_dbus_pldm_hmc_erot_uuid() {
local gpu_pldm_erot_id="$1"
erot_id=${gpu_pldm_erot_id:-HGX_ERoT_GPU_SXM_1} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/inventory/system/chassis/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

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
id=${sw_id:-"HGX_FW_GPU_SXM_1"} && _log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
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
    return 1
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
    return 1
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
    return 1
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
    return 1
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
    return 1
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

# HMC-GPU_IROT-PLDM_T5-08
# Function to get PLDM fw_update PCI Vendor ID of GPU
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Vendor" ID
get_gpu_irot_pldm_pci_vendor_id() {
local sku_eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${sku_eid:-32} && key=${sku_key:-"PCI Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-GPU_IROT-PLDM_T5-09
# Function to get PLDM fw_update PCI Device ID of GPU
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Device" ID
get_gpu_irot_pldm_pci_device_id() {
local sku_eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${sku_eid:-32} && key=${sku_key:-"PCI Device ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-GPU_IROT-PLDM_T5-10
# Function to get PLDM fw_update PCI Subsystem Vendor ID of GPU
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem Vendor" ID
get_gpu_irot_pldm_pci_subsys_vendor_id() {
local sku_eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${sku_eid:-32} && key=${sku_key:-"PCI Subsystem Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-GPU_IROT-PLDM_T5-11
# Function to get PLDM fw_update PCI Subsystem ID of GPU
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem" ID
get_gpu_irot_pldm_pci_subsys_id() {
local sku_eid="$1"
# default EID to 32, GPU #5 IRoT
eid=${sku_eid:-32} && key=${sku_key:-"PCI Subsystem ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-GPU_IROT-DBUS-07
# Function to get PLDM DBus software inventory version of GPU iRoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid iRoT FW version
get_dbus_pldm_gpu_irot_version() {
local gpu_pldm_irot_id="$1"
irot_id=${gpu_pldm_irot_id:-"HGX_FW_GPU_SXM_1"} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$irot_id" | grep '^\.Version' | grep -o '"[^"]*"'| tr -d '"') && echo $output
}

# HMC-GPU_EROT-PLDM_T5-01
# Function to get PLDM fw_update version of GPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_gpu_erot_pldm_version() {
local eid="$1"
# default EID to 26, GPU ERoT
eid=${eid:-26} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
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

## GPU: Security Protocol

# HMC-GPU_EROT-SPDM-01
# Function to get SPDM Version through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Version
get_gpu_erot_spdm_version() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_GPU_SXM_1'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Version | cut -d ' ' -f 2) && echo $output
}

# HMC-GPU_EROT-SPDM-02
# Function to get SPDM Measurements Type through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Measurements Type
get_gpu_erot_spdm_measurements_type() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_GPU_SXM_1'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder MeasurementsType | tr -d '"' | cut -d '.' -f 6) && echo $output
}

# HMC-GPU_EROT-SPDM-03
# Function to get SPDM Algorithms through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Algorithms
get_gpu_erot_spdm_hash_algorithms() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_GPU_SXM_1'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder HashingAlgorithm | cut -d ' ' -f 2 | cut -d '.' -f 6 | tr -d '"')
id=${spdm_id:-'HGX_ERoT_GPU_SXM_1'} && output+=" $(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder SigningAlgorithm | cut -d ' ' -f 2 | cut -d '.' -f 6 | tr -d '"')"
echo "$output"
}

# HMC-GPU_EROT-SPDM-04
# Function to get SPDM Measurement of Serial Number (index 27)
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid "yes", "no" otherwise
get_gpu_erot_spdm_measurement_serial_number() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_GPU_SXM_1'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Measurements) && [[ -n $output ]] && echo "yes" || echo "no"
}

# HMC-GPU_EROT-SPDM-05
# Function to get SPDM Measurement of Token Request (index 50)
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid "yes", "no" otherwise
get_gpu_erot_spdm_measurement_token_request() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_GPU_SXM_1'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Measurements) && [[ -n $output ]] && echo "okay" || echo "no"
}

# HMC-GPU_EROT-SPDM-06
# Function to get SPDM Certificate count through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Certificate count
get_gpu_erot_spdm_certificate_count() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_GPU_SXM_1'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Certificate | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $output
}

# HMC-GPU_IROT-SPDM-07
# Function to get SPDM NVDA Certificate count using spdmtool
# Arguments:
#   $1: EID
#   $2: Slot ID
# Returns:
#   valid SPDM Certificate count
get_gpu_irot_certificate_count_spdmtool_nvda() {
local input_eid="$1"
local slot_id="$2"
# default EID to 28, GPU SXM_1; slot to 0, NVDA cert chain
eid=${input_eid:-28} && slot=${slot_id:-0} && count=$(_log_ spdmtool -e ${eid} get-cert --slot ${slot} | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $count
}


## Retimer: Firmware Update Protocol

# HMC-Retimer-Version-01
# Function to get Retimer FW version from dbus via GPU Manager
# Arguments:
#   $1: Software ID
# Returns:
#   valid Retimer FW version
get_retimer_fw_version_dbus_gpumgr() {
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
# regular out 0x5d: Bit[15:0] Major version, Bit[31:16] Minvor version
# extended out 0x5e: Bit 31:0 build number
bus=${i2c_bus:-3} && addr=${i2c_addr:-0x60} && reg=${register:-0x90} && output=$(_log_ i2ctransfer -f -y "$bus" w6@"$addr" 0x5c 0x04 0x05 "$reg" 0x00 0x80; i2ctransfer -f -y "$bus" w1@"$addr" 0x5d r5 | cut -d ' ' -f 2-6) && output="$output $(i2ctransfer -f -y "$bus" w1@"$addr" 0x5e r5 | cut -d ' ' -f 2-6)" && echo "$output"
}

# HMC-Retimer-Version-03
# Function to get Retimer FW version from NSM dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid Retimer FW version
get_retimer_fw_version_dbus_nsm() {
local sw_id="$1"
# default to HGX_FW_PCIeRetimer_0
id=${sw_id:-HGX_FW_PCIeRetimer_0} && _log_ busctl get-property xyz.openbmc_project.NSM /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-Retimer-Version-04
# Function to get Retimer FW version from FPGA via NSM
# Arguments:
#   $1: MCTP EID for FPGA
#   $1: Request Data 1
# Returns:
#   valid Retimer FW version
get_retimer_fw_version_nsm() {
local fpga_bridge_eid="$1"
local req_1="$2"
local cmd=0x0c

# default EID to 12, FPGA MCTP Bridge EID
# the 'nsmtool' outputs to journal log
eid=${fpga_bridge_eid:-12} && cmd=${cmd:-"0x0c"} && req=${req_1:-"0x90"} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x03 $cmd 0x01 "${req}" -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12,19p' | awk '{print "0x"$0}' | tr '\n' ' ') && [[ $output ]] && echo "$output" || echo ""
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
    return 1
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
    return 1
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
    return 1
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
    return 1
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
    return 1
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

# HMC-CX7_EROT-PLDM_T5-08
# Function to get PLDM fw_update PCI Vendor ID of CX7 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Vendor" ID
get_cx7_erot_pldm_pci_vendor_id() {
local sku_eid="$1"
# default EID to 17, CX7 ERoT
eid=${sku_eid:-17} && key=${sku_key:-"PCI Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-CX7_EROT-PLDM_T5-09
# Function to get PLDM fw_update PCI Device ID of CX7 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Device" ID
get_cx7_erot_pldm_pci_device_id() {
local sku_eid="$1"
# default EID to 17, CX7 ERoT
eid=${sku_eid:-17} && key=${sku_key:-"PCI Device ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-CX7_EROT-PLDM_T5-10
# Function to get PLDM fw_update PCI Subsystem Vendor ID of CX7 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem Vendor" ID
get_cx7_erot_pldm_pci_subsys_vendor_id() {
local sku_eid="$1"
# default EID to 17, CX7 ERoT
eid=${sku_eid:-17} && key=${sku_key:-"PCI Subsystem Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-CX7_EROT-PLDM_T5-11
# Function to get PLDM fw_update PCI Subsystem ID of CX7 ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem" ID
get_cx7_erot_pldm_pci_subsys_id() {
local sku_eid="$1"
# default EID to 17, CX7 ERoT
eid=${sku_eid:-17} && key=${sku_key:-"PCI Subsystem ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-CX7_EROT-DBUS-08
# Function to get PLDM DBus software inventory version of CX7 ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid ERoT FW version
get_dbus_pldm_cx7_erot_version() {
local cx7_pldm_erot_id="$1"
erot_id=${cx7_pldm_erot_id:-HGX_FW_ERoT_NVLinkManagementNIC_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$erot_id" | grep '^\.Version' | grep -o '"[^"]*"' | tr -d '"') && echo $output
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

## CX7: Security Protocol

# HMC-CX7_EROT-Key-01
# Function to get EC key revoke policy via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid revoke policy
get_cx7_erot_key_revoke_policy_i2c() {
local i2c_addr="${1:-0x74}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke policy", cmd=0x1d, arg=0x00, read length=20
response=$(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x1d 0x00 20)

output=${response:90:4}

case $output in
0x00) echo "not set";;
0x01) echo "auto";;
0x02) echo "decoupled";;
*) echo "unknown";;
esac
}

# HMC-CX7_EROT-Key-02
# Function to get EC key revoke policy via VDM
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid revoke policy
get_cx7_erot_key_revoke_policy_vdm() {
local cx7_erot_spi_eid="$1"

# default EID to 17, CX7 MCTP ERoT SPI
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${cx7_erot_spi_eid:-17} && output=$(_log_ mctp-pcie-ctrl -s "7f 00 00 16 47 80 01 1d 01 00" -t 2 -e "${eid}" -i 9 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 11)

case $output in
00) echo "not set";;
01) echo "auto";;
02) echo "decoupled";;
*) echo "unknown";;
esac
}

# HMC-CX7_EROT-Key-03
# Function to get EC key revoke state via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid EC key revoke state
get_cx7_erot_ec_key_revoke_state_i2c() {
local i2c_addr="${1:-0x74}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke", selftest cmd=0x08, arg=0x08, read length=61
response=($(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x08 0x08 61))

# EC Key Revoke state
echo ${response[35]}
}

# HMC-CX7_EROT-Key-04
# Function to get EC key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_cx7_erot_ec_key_revoke_state_vdm() {
local cx7_erot_eid="$1"
local eid
local response
local output
# default 17 to CX7 ERoT EID
eid=${cx7_erot_eid:-17} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[18]}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-CX7_EROT-Key-05
# Function to get AP key revoke state via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid EC key revoke state
get_cx7_erot_ap_key_revoke_state_i2c() {
local i2c_addr="${1:-0x74}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke", selftest cmd=0x08, arg=0x08, read length=61
response=($(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x08 0x08 61))

# AP Key Revoke state
output=${response[@]:52:8}
echo $output
}

# HMC-CX7_EROT-Key-06
# Function to get AP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_cx7_erot_ap_key_revoke_state_vdm() {
local cx7_erot_eid="$1"
local eid
local response
local output
# default 17 to CX7 ERoT EID
eid=${cx7_erot_eid:-17} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:35:8}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-CX7_EROT-Key-07
# Function to get EC RBP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC RBP key revoke state
get_cx7_erot_ec_rbp_key_revoke_state_vdm() {
local cx7_erot_eid="$1"
local eid
local response
local output
# default 17 to CX7 ERoT EID
eid=${cx7_erot_eid:-17} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:2:16}
else
    # Invalid
    output=""
fi

# EC RBP Key Revoke state
echo $output
}

# HMC-CX7_EROT-Key-08
# Function to get AP RBP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP RBP key revoke state
get_cx7_erot_ap_rbp_key_revoke_state_vdm() {
local cx7_erot_eid="$1"
local eid
local response
local output
# default 17 to CX7 ERoT EID
eid=${cx7_erot_eid:-17} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:19:16}
else
    # Invalid
    output=""
fi

# AP RBP Key Revoke state
echo $output
}

# HMC-CX7_EROT-Security-01
# Function to get EC background copy progress state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC background copy progress state
get_cx7_erot_background_copy_progress_state_vdm() {
local cx7_erot_eid="$1"
local eid
local response
local output
# default 17 to FPGA ERoT EID
eid=${cx7_erot_eid:-17} && response=($(_log_ mctp-vdm-util -t ${eid} -c background_copy_query_progress | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-11))

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[1]}
else
    # Invalid
    output=""
fi

case $output in
01) echo "copy not in progress";;
02) echo "copy in progress";;
*) echo "unknown";;
esac
}

# HMC-CX7_EROT-SPDM-06
# Function to get SPDM NVDA Certificate count using spdmtool
# Arguments:
#   $1: EID
#   $2: Slot ID
# Returns:
#   valid SPDM Certificate count
get_cx7_erot_spdm_certificate_count_spdmtool_nvda() {
local input_eid="$1"
local slot_id="$2"
# default EID to 17, CX7 ERoT; slot to 0, NVDA cert chain
eid=${input_eid:-17} && slot=${slot_id:-0} && count=$(_log_ spdmtool -e ${eid} get-cert --slot ${slot} | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $count
}

# HMC-CX7_EROT-SPDM-07
# Function to get SPDM MCHP Certificate count using spdmtool
# Arguments:
#   $1: EID
#   $2: Slot ID
# Returns:
#   valid SPDM Certificate count
get_cx7_erot_spdm_certificate_count_spdmtool_mchp() {
local input_eid="$1"
local slot_id="$2"
# default EID to 17, CX7 ERoT; slot to 1, MCHP cert chain
eid=${input_eid:-17} && slot=${slot_id:-1} && count=$(_log_ spdmtool -e ${eid} get-cert --slot ${slot} | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $count
}

## NVSWITCH: Transport Protocol

# HMC-NVSWITCH-VFIO_SMBPBI-01
# Function to get NVSW FW version through VFIO SMBPBI Proxy
# Arguments:
#   $1: Software ID
# Returns:
#   valid NVSW version
get_nvswitch_version_vfio_smbpbi_proxy() {
local sw_id="$1"
id=${sw_id:-HGX_FW_NVSwitch_1} && _log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-NVSWITCH-I2C_SMBPBI-01
# Function to get NVSWITCH FW version through SMBPBI on I2C-3 bus
# Arguments:
#   $1: I2C Bus number for the BMC I2C-3 (i2c 2)
#   $2: I2C Addr for the NVSWITCH SMBPBI server
#   $3: Register Addr for the target component
# Returns:
#   valid NVSWITCH FW version
get_nvswitch_version_i2c_smbpbi() {
local i2c_bus="$1"
local i2c_addr="$2"
local register="$3"
local output
bus=${i2c_bus:-1} && addr=${i2c_addr:-0x19} && reg=${register:-0x8} && output=$(_log_ i2ctransfer -f -y "$bus" w6@"$addr" 0x5c 0x04 0x05 "$reg" 0x00 0x80; i2ctransfer -f -y "$bus" w1@"$addr" 0x5d r14 | cut -d ' ' -f 2-6) && echo "$output"
}

# HMC-NVSWITCH_EROT-MCTP_VDM-01
# Function to get the enumrated MCTP EID, NVSWITCH ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid EID
get_nvswitch_erot_mctp_eid_spi() {
local nvswitch_erot_spi_eid="$1"

# default EID to 15, NVSWITCH #1 MCTP ERoT SPI
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${nvswitch_erot_spi_eid:-15} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-NVSWITCH_EROT-MCTP_VDM-02
# Function to get the enumrated MCTP EID, NVSWITCH ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid EID
get_nvswitch_erot_mctp_eid_i2c() {
local nvswitch_erot_i2c_eid="$1"

# default EID to 19, Umbriel NVSWITCH #1 MCTP ERoT I2C
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${nvswitch_erot_i2c_eid:-19} && eid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5) && printf "%d\n" 0x$eid_rt
}

# HMC-NVSWITCH_EROT-MCTP_VDM-03
# Function to get the MCTP UUID for NVSWITCH ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_nvswitch_erot_mctp_uuid_spi() {
local nvswitch_erot_spi_eid="$1"

# default EID to 15, NVSWITCH #1 MCTP ERoT SPI
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${nvswitch_erot_spi_eid:-15} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

# HMC-NVSWITCH_EROT-MCTP_VDM-04
# Function to get the MCTP UUID for NVSWITCH ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_nvswitch_erot_mctp_uuid_i2c() {
local nvswitch_erot_i2c_eid="$1"

# default EID to 19, NVSWITCH #1 MCTP ERoT I2C
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${nvswitch_erot_i2c_eid:-19} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

# HMC-NVSWITCH_EROT-DBUS-13
# Function to get NVSWITCH ERoT-SPI MCTP UUID via MCTP over VDM through DBus
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid MCTP UUID
get_nvswitch_dbus_mctp_vdm_spi_uuid() {
local eid="$1"
local output

# default EID to 15, NVSWITCH ERoT via MCTP over VDM
erot_id=${eid:-15} && output=$(_log_ busctl introspect xyz.openbmc_project.MCTP.Control.PCIe /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

# HMC-NVSWITCH_EROT-DBUS-14
# Function to get NVSWITCH ERoT-I2C MCTP UUID via MCTP over VDM through DBus
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid MCTP UUID
get_nvswitch_dbus_mctp_vdm_i2c_uuid() {
local eid="$1"
local output

# default EID to 21, NVSWITCH ERoT via MCTP over VDM
erot_id=${eid:-21} && output=$(_log_ busctl introspect xyz.openbmc_project.MCTP.Control.PCIe /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

## NVSWITCH: Base Protocol

# HMC-NVSWITCH_EROT-PLDM_T0-01
# Function to get PLDM base GetTID of NVSWITCH ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_nvswitch_erot_pldm_tid() {
local nvswitch_eid="$1"
eid=${nvswitch_eid:-15} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-NVSWITCH_EROT-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of NVSWITCH ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_nvswitch_erot_pldm_pldmtypes() {
local nvswitch_eid="$1"
eid=${nvswitch_eid:-15} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-NVSWITCH_EROT-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of NVSWITCH ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_nvswitch_erot_pldm_t0_pldmversion() {
local nvswitch_eid="$1"
eid=${nvswitch_eid:-15} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-NVSWITCH_EROT-PLDM_T0-04
# Function to get PLDM base GetPLDMVersion T5 of NVSWITCH ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_nvswitch_erot_pldm_t5_pldmversion() {
local nvswitch_eid="$1"
eid=${nvswitch_eid:-15} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-NVSWITCH-PLDM_T0-01
# Function to get PLDM base GetTID of NVSWITCH
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_nvswitch_pldm_tid() {
local nvswitch_eid="$1"
eid=${nvswitch_eid:-22} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-NVSWITCH-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of NVSWITCH
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_nvswitch_pldm_pldmtypes() {
local nvswitch_eid="$1"
eid=${nvswitch_eid:-22} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-NVSWITCH-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of NVSWITCH
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_nvswitch_pldm_t0_pldmversion() {
local nvswitch_eid="$1"
eid=${nvswitch_eid:-22} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-NVSWITCH-PLDM_T0-04
# Function to get PLDM base GetPLDMVersion T2 of NVSWITCH
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_nvswitch_pldm_t2_pldmversion() {
local nvswitch_eid="$1"
eid=${nvswitch_eid:-22} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 2 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-NVSWITCH-PLDM_T0-05
# Function to get PLDM base GetPLDMVersion T5 of NVSWITCH
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_nvswitch_pldm_t5_pldmversion() {
local nvswitch_eid="$1"
eid=${nvswitch_eid:-22} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-NVSWITCH-NSM_T0-01
# Function to verify if NSM PING functional via MCTP VDM
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "yes", "no" otherwise
is_nvswitch_mctp_vdm_nsm_ping_operational() {
local nvswitch_eid="$1"
local cmd=00

# default EID to 22, NVSWITCH MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${nvswitch_eid:-22} && [[ "00" = $(_log_ mctp-pcie-ctrl -s "7e 10 de 80 89 00 $cmd 00" -t 2 -e "${eid}" -i 9 -p 12 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f8) ]] && echo "yes" || echo "no"
}

# HMC-NVSWITCH-NSM_T0-02
# Function to verify if NSM PING functional using nsmtool
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "yes", "no" otherwise
is_nvswitch_mctp_nsmtool_ping_operational() {
local nvswitch_eid="$1"
local cmd=0x00

# default EID to 22, NVSWITCH MCTP EID
# the 'nsmtool' outputs to journal log
eid=${nvswitch_eid:-22} && [[ "00" = $(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '7p') ]] && echo "yes" || echo "no"
}

# HMC-NVSWITCH-NSM_T0-03
# Function to verify NSM Get Supported Message Types via MCTP VDM
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "0x3b", fault otherwise
get_nvswitch_mctp_vdm_nsm_supported_message_types() {
local nvswitch_eid="$1"
local cmd=01

# default EID to 22, NVSWITCH MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${cx7_eid:-22} && output=$(_log_ mctp-pcie-ctrl -s "7e 10 de 80 89 00 $cmd 00" -t 2 -e "${eid}" -i 9 -p 12 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f13) && echo "$output"
}

# HMC-NVSWITCH-NSM_T0-04
# Function to verify NSM Get Supported Message Types using nsmtool
# Arguments:
#   $1: MCTP EID to verify the NSM
# Returns:
#   valid "0x3b", fault otherwise
get_nvswitch_mctp_nsmtool_supported_message_types() {
local nvswitch_eid="$1"
local cmd=0x01

# default EID to 22, NVSWITCH MCTP EID
# the 'nsmtool' outputs to journal log
eid=${nvswitch_eid:-22} && output=$(_log_ nsmtool raw -d 0x10 0xde 0x80 0x89 0x00 $cmd 0x00 -m "${eid}" -v | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '12p') && [[ $output ]] && echo "$output" || echo ""
}

## NVSWITCH: Firmware Update Protocol

# HMC-NVSWITCH_EROT-Version-01
# Function to get NVSWITCH ERoT FW version from PLDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_nvswitch_erot_fw_version_pldm() {
local eid="$1"
local output
# default EID to 15, NVSWITCH #1 ERoT SPI
eid=${eid:-15} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-NVSWITCH_EROT-Version-02
# Function to get NVSWITCH ERoT FW version from PLDM dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid ERoT FW version
get_nvswitch_erot_fw_version_pldm_dbus() {
local sw_id="$1"
# default HGX_FW_ERoT_NVSWITCH_0
id=${sw_id:-HGX_FW_ERoT_NVSwitch_0} && _log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-NVSWITCH_EROT-Version-03
# Function to get NVSWITCH ERoT FW Build Type
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Build Type
get_nvswitch_erot_fw_build_type() {
local nvswitch_erot_eid="$1"
# default EID to 15, NVSWITCH #1 ERoT SPI
# 0: rel, 1: dev
eid=${nvswitch_erot_eid:-15} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
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

# HMC-NVSWITCH_EROT-Version-04
# Function to get NVSWITCH ERoT FW Keyset
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Keyset
get_nvswitch_erot_fw_keyset() {
local nvswitch_erot_eid="$1"
# default EID to 15, NVSWITCH #1 ERoT SPI
# 0: s1, 1: s2, 2: s3, 3: s4, 4: s5
eid=${nvswitch_erot_eid:-15} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
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

# HMC-NVSWITCH_EROT-Version-05
# Function to get NVSWITCH ERoT FW Chip Rev
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Chip Rev
get_nvswitch_erot_fw_chiprev() {
local nvswitch_erot_eid="$1"
# default EID to 15, NVSWITCH #1 ERoT SPI
# 0: revA, 1:revB
eid=${nvswitch_erot_eid:-15} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
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

# HMC-NVSWITCH_EROT-Version-06
# Function to get NVSWITCH ERoT FW Boot Slot
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Boot Slot
get_nvswitch_erot_fw_boot_slot() {
local nvswitch_erot_eid="$1"
# default EID to 15, NVSWITCH #1 ERoT SPI
eid=${nvswitch_erot_eid:-17} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
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

# HMC-NVSWITCH_EROT-Version-07
# Function to get NVSWITCH ERoT FW EC Identical
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW EC Identical
get_nvswitch_erot_fw_ec_identical() {
local nvswitch_erot_eid="$1"
# default EID to 15, NVSWITCH #1 ERoT SPI
# 0: identical, 1: not identical
eid=${nvswitch_erot_eid:-17} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
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

# HMC-NVSWITCH_EROT-PLDM_T5-01
# Function to get PLDM fw_update version of NVSWITCH_EROT SPI
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_nvswitch_erot_pldm_version() {
local eid="$1"
# default EID to 15, NVSWITCH #1 SPI ERoT
eid=${eid:-15} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-NVSWITCH_EROT-PLDM_T5-02
# Function to get PLDM fw_update version of NVSWITCH
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid FW version
get_nvswitch_erot_pldm_version_string() {
local eid="$1"
# default EID to 15, NVSWITCH #1 SPI ERoT
eid=${eid:-15} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==2') && echo $output
}

# HMC-NVSWITCH_EROT-PLDM_T5-05
# Function to get PLDM fw_update AP_SKU ID of NVSWITCH
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_nvswitch_erot_pldm_apsku_id() {
local sku_eid="$1"
# default EID to 15, NVSWITCH #1 SPI ERoT
eid=${sku_eid:-15} && key=${sku_key:-APSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-NVSWITCH_EROT-PLDM_T5-06
# Function to get PLDM fw_update EC_SKU ID of NVSWITCH ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_nvswitch_erot_pldm_ecsku_id() {
local sku_eid="$1"
# default EID to 15, NVSWITCH #1 SPI ERoT
eid=${sku_eid:-15} && key=${sku_key:-ECSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-NVSWITCH_EROT-PLDM_T5-07
# Function to get PLDM fw_update GLACIERDSD of NVSWITCH ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_nvswitch_erot_pldm_glacier_id() {
local sku_eid="$1"
# default EID to 15, NVSWITCH #1 SPI ERoT
eid=${sku_eid:-15} && key=${sku_key:-GLACIERDSD} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-NVSWITCH_EROT-DBUS-03
# Function to get PLDM DBus chassis inventory UUID of NVSWITCH ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid MCTP UUID
get_nvswitch_dbus_pldm_hmc_erot_uuid() {
local nvswitch_pldm_erotid="$1"
erot_id=${nvswitch_pldm_erot_id:-HGX_ERoT_NVSwitch_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/inventory/system/chassis/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}


# HMC-NVSWITCH_EROT-PLDM_T5-08
# Function to get PLDM fw_update PCI Vednor ID of NVSWITCH ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Vendor" ID
get_nvswitch_erot_pldm_pci_vendor_id() {
local sku_eid="$1"
# default EID to 15, NVSWITCH #1 SPI ERoT
eid=${sku_eid:-15} && key=${sku_key:-"PCI Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-NVSWITCH_EROT-PLDM_T5-09
# Function to get PLDM fw_update PCI Device ID of NVSWITCH ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Device" ID
get_nvswitch_erot_pldm_pci_device_id() {
local sku_eid="$1"
# default EID to 15, NVSWITCH #1 SPI ERoT
eid=${sku_eid:-15} && key=${sku_key:-"PCI Device ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-NVSWITCH_EROT-PLDM_T5-10
# Function to get PLDM fw_update Subsystem Vendor ID of NVSWITCH ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem Vendor" ID
get_nvswitch_erot_pldm_pci_subsys_vendor_id() {
local sku_eid="$1"
# default EID to 15, NVSWITCH #1 SPI ERoT
eid=${sku_eid:-15} && key=${sku_key:-"PCI Subsystem Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-NVSWITCH_EROT-PLDM_T5-11
# Function to get PLDM fw_update Subsystem ID of NVSWITCH ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem" ID
get_nvswitch_erot_pldm_pci_subsys_id() {
local sku_eid="$1"
# default EID to 15, NVSWITCH #1 SPI ERoT
eid=${sku_eid:-15} && key=${sku_key:-"PCI Subsystem ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-NVSWITCH_EROT-DBUS-09
# Function to get PLDM DBus software inventory version of NVSWITCH ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid ERoT FW version
get_dbus_pldm_nvswitch_erot_version() {
local nvswitch_pldm_erot_id="$1"
erot_id=${nvswitch_pldm_erot_id:-HGX_FW_ERoT_NVSwitch_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$erot_id" | grep '^\.Version' | grep -o '"[^"]*"') && echo $output
}

## NVSWITCH: Telemetry Protocol

# HMC-NVSWITCH-PLDM_T2-02
# Function to disable PLDM T2 sensor polling
# Arguments:
#   n/a
# Returns:
#   valid "done", "failed" otherwise
_disable_nvswitch_sensor_polling() {
local output
_log_ busctl set-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled b false
output=$(_log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled | grep -o "false"); [[ $output = "false" ]] && echo "done" || echo "failed"
}

# HMC-NVSWITCH-PLDM_T2-03
# Function to enable PLDM T2 sensor polling
# Arguments:
#   n/a
# Returns:
#   valid "done", "failed" otherwise
enable_nvswitch_sensor_polling() {
local output
_log_ busctl set-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled b true
output=$(_log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/pldm/sensor_polling xyz.openbmc_project.Object.Enable Enabled | grep -o "true"); [[ $output = "true" ]] && echo "done" || echo "failed"
}

# HMC-NVSWITCH-PLDM_T2-04
# Function to dump NVSWITCH PDR in JSON format
# Arguments:
#   NVSWITCH EID
# Returns:
#   valid "done", "failed" otherwise
dump_nvswitch_pdr_json() {
local nvswitch_eid="$1"
local jsonfile=/tmp/"$FUNCNAME"_output.json
# default EID to 22, NVSWITCH #1 I2C
eid=${nvswitch_eid:-22} && logfile=${jsonfile:-"/tmp/func_output.json"} && _log_ pldmtool platform getpdr -m "$eid" -a > "$logfile" && [ $(wc -c < $logfile) -gt 10 ] && : || rm $logfile && [ -f "$logfile" ] && echo "done" || echo "failed"
}

# HMC-NVSWITCH-PLDM_T2-05
# Function to get NVSWITCH Numeric Sensor ID
# Arguments:
#   NVSWITCH EID
# Returns:
#   Numeric Sesnor ID
get_nvswitch_numeric_sensor_id() {
local nvswitch_eid="$1"
# default EID to 22, NVSWITCH #1 I2C
eid=${nvswitch_eid:-22} && output=$(_log_ pldmtool platform getpdr -m "$eid" -a 2>/dev/null | grep -A5 'Numeric Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}'); echo "$output"
}

# HMC-NVSWITCH-PLDM_T2-06
# Function to verify if NVSWITCH Numeric Sensor ID is accessible
# Arguments:
#   NVSWITCH EID
# Returns:
#   valid "yes", "no" otherwise
is_nvswitch_numeric_sensor_accessible() {
    local nvswitch_eid="$1"
    # default EID to 22, NVSWITCH #1 I2C
    eid=${nvswitch_eid:-22} && sensor_ids=$(_log_ pldmtool platform getpdr -m "$eid" -a | grep -A5 'Numeric Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}')
    [ -z "$sensor_ids" ] && echo 'no' && return

    # Convert the string into an array
    IFS=' ' read -ra sensor_array <<< "$sensor_ids"

    # Get the last sensord readout
    [[ "00" = $(_log_ pldmtool raw -m "$eid" -v -d 0x80 0x02 0x11 0x$(printf "%x" ${sensor_array[-1]}) 0x00 0x0 0x0 | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '4p') ]] && echo "yes" || echo "no"
}

# HMC-NVSWITCH-PLDM_T2-07
# Function to get NVSWITCH State Sensor IDs
# Arguments:
#   NVSWITCH EID
# Returns:
#   Numeric Sesnor ID
get_nvswitch_state_sensor_id() {
# Todo: filter out only State Sensor ID
local nvswitch_eid="$1"
# default EID to 22, NVSWITCH #1 I2C
eid=${nvswitch_eid:-22} && output=$(_log_ pldmtool platform getpdr -m "$eid" -a 2>/dev/null | grep -A5 'State Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}'); echo "$output"
}

# HMC-NVSWITCH-PLDM_T2-08
# Function to verify if all NVSWITCH State Sensor ID is accessible
# Arguments:
#   NVSWITCH EID
# Returns:
#   valid "yes", "no" otherwise
is_nvswitch_state_sensor_accessible() {
    local nvswitch_eid="$1"
    # default EID to 22, NVSWITCH #1 I2C
    eid=${nvswitch_eid:-22} && state_ids=$(_log_ pldmtool platform getpdr -m "$eid" -a | grep -A5 'State Sensor PDR' | awk -F': ' '/"sensorID":/ {print $2}' | tr -d ',' | sort -n | uniq | awk '{printf "%s ", $0} END {print ""}')
    [ -z "$sensor_ids" ] && echo 'no' && return

    # Convert the string into an array
    IFS=' ' read -ra sensor_array <<< "$state_ids"

    # Get the last sensord readout
    [[ "00" = $(_log_ pldmtool raw -m "$eid" -v -d 0x80 0x02 0x21 0x$(printf "%x" ${sensor_array[-1]}) 0x00 0x0 0x0 | grep -o 'Rx.*' | grep -o '[0-9a-fA-F]\+'| sed -n '4p') ]] && echo "yes" || echo "no"
}

## NVSWITCH: Security Protocol

# HMC-NVSWITCH_EROT-SPDM-01
# Function to get SPDM Version through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Version
get_nvswitch_erot_spdm_version() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_NVSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Version | cut -d ' ' -f 2) && echo $output
}

# HMC-NVSWITCH_EROT-SPDM-02
# Function to get SPDM Measurements Type through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Measurements Type
get_nvswitch_erot_spdm_measurements_type() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_NVSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder MeasurementsType | tr -d '"' | cut -d '.' -f 6) && echo $output
}

# HMC-NVSWITCH_EROT-SPDM-03
# Function to get SPDM Algorithms through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Algorithms
get_nvswitch_erot_spdm_hash_algorithms() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_NVSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder HashingAlgorithm | cut -d ' ' -f 2 | cut -d '.' -f 6 | tr -d '"')
id=${spdm_id:-'HGX_ERoT_NVSwitch_0'} && output+=" $(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder SigningAlgorithm | cut -d ' ' -f 2 | cut -d '.' -f 6 | tr -d '"')"
echo "$output"
}

# HMC-NVSWITCH_EROT-SPDM-04
# Function to get SPDM Measurement of Serial Number (index 27)
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid "yes", "no" otherwise
get_nvswitch_erot_spdm_measurement_serial_number() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_NVSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Measurements) && [[ -n $output ]] && echo "yes" || echo "no"
}

# HMC-NVSWITCH_EROT-SPDM-05
# Function to get SPDM Measurement of Token Request (index 50)
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid "yes", "no" otherwise
get_nvswitch_erot_spdm_measurement_token_request() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_NVSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Measurements) && [[ -n $output ]] && echo "okay" || echo "no"
}

# HMC-NVSwitch_EROT-SPDM-06
# Function to get SPDM Certificate count through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Certificate count
get_nvswitch_erot_spdm_certificate_count() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_NVSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Certificate | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $output
}

# HMC-NVSwitch_EROT-SPDM-07
# Function to get SPDM NVDA Certificate count using spdmtool
# Arguments:
#   $1: EID
#   $2: Slot ID
# Returns:
#   valid SPDM Certificate count
get_nvswitch_erot_spdm_certificate_count_spdmtool_nvda() {
local input_eid="$1"
local slot_id="$2"
# default EID to 15, NVSwitch_0 ERoT; slot to 0, NVDA cert chain
eid=${input_eid:-15} && slot=${slot_id:-0} && count=$(_log_ spdmtool -e ${eid} get-cert --slot ${slot} | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $count
}

# HMC-NVSwitch_EROT-SPDM-08
# Function to get SPDM MCHP Certificate count using spdmtool
# Arguments:
#   $1: EID
#   $2: Slot ID
# Returns:
#   valid SPDM Certificate count
get_nvswitch_erot_spdm_certificate_count_spdmtool_mchp() {
local input_eid="$1"
local slot_id="$2"
# default EID to 15, NVSwitch_0 ERoT; slot to 1, MCHP cert chain
eid=${input_eid:-15} && slot=${slot_id:-1} && count=$(_log_ spdmtool -e ${eid} get-cert --slot ${slot} | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $count
}

# HMC-NVSWITCH_IROT-01
# Function to verify IROT fused
# Arguments:
#   $1: I2C Address
#   $2: I2C Bus
# Returns:
#   valid "yes", "no" otherwise
is_nvswitch_irot_fused() {
local i2c_addr="${1:-0x29}"
local i2c_bus="${2:-3}"
local mask="${3:-0x07}"
out=$(_log_ i2ctransfer -y "$i2c_bus" w4@"$i2c_addr" 0x00 0x0f 0x00 0x00 r4 | awk '{print $2}'); [[ -n $out ]] && [[ $((16#${out#0x} & $mask)) = 6 ]] && echo "yes" || echo "no"
}

# HMC-NVSWITCH_EROT-Key-01
# Function to get EC key revoke policy via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid revoke policy
get_nvswitch_erot_key_revoke_policy_i2c() {
local i2c_addr="${1:-0x71}"
# WAR to Glacier hardware strapping, changing from 0x52 to 0x42
local i2c_addr_dest="${2:-0x42}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke policy", cmd=0x1d, arg=0x00, read length=20
response=$(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x1d 0x00 20)

output=${response:90:4}

case $output in
0x00) echo "not set";;
0x01) echo "auto";;
0x02) echo "decoupled";;
*) echo "unknown";;
esac
}

# HMC-NVSWITCH_EROT-Key-02
# Function to get EC key revoke policy via VDM
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid revoke policy
get_nvswitch_erot_key_revoke_policy_vdm() {
local nvswitch_erot_spi_eid="$1"

# default EID to 15, NVSWITCH MCTP ERoT SPI
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${nvswitch_erot_spi_eid:-15} && output=$(_log_ mctp-pcie-ctrl -s "7f 00 00 16 47 80 01 1d 01 00" -t 2 -e "${eid}" -i 9 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 11)

case $output in
00) echo "not set";;
01) echo "auto";;
02) echo "decoupled";;
*) echo "unknown";;
esac
}

# HMC-NVSWITCH_EROT-Key-03
# Function to get EC key revoke state via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid EC key revoke state
get_nvswitch_erot_ec_key_revoke_state_i2c() {
local i2c_addr="${1:-0x71}"
# WAR to Glacier hardware strapping, changing from 0x52 to 0x42
local i2c_addr_dest="${2:-0x42}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke", selftest cmd=0x08, arg=0x08, read length=61
response=($(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x08 0x08 61))

# EC Key Revoke state
echo ${response[35]}
}

# HMC-NVSWITCH_EROT-Key-04
# Function to get EC key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_nvswitch_erot_ec_key_revoke_state_vdm() {
local nvswitch_erot_eid="$1"
local eid
local response
local output
# default 15 to NVSWITCH ERoT EID
eid=${nvswitch_erot_eid:-15} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[18]}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-NVSWITCH_EROT-Key-05
# Function to get AP key revoke state via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid EC key revoke state
get_nvswitch_erot_ap_key_revoke_state_i2c() {
local i2c_addr="${1:-0x71}"
# WAR to Glacier hardware strapping, changing from 0x52 to 0x42
local i2c_addr_dest="${2:-0x42}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke", selftest cmd=0x08, arg=0x08, read length=61
response=($(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x08 0x08 61))

# AP Key Revoke state
output=${response[@]:52:8}
echo $output
}

# HMC-NVSWITCH_EROT-Key-06
# Function to get AP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_nvswitch_erot_ap_key_revoke_state_vdm() {
local nvswitch_erot_eid="$1"
local eid
local response
local output
# default 15 to NVSWITCH ERoT EID
eid=${nvswitch_erot_eid:-15} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:35:8}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-NVSWITCH_EROT-Key-07
# Function to get EC RBP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC RBP key revoke state
get_nvswitch_erot_ec_rbp_key_revoke_state_vdm() {
local nvswitch_erot_eid="$1"
local eid
local response
local output
# default 15 to NVSWITCH ERoT EID
eid=${nvswitch_erot_eid:-15} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:2:16}
else
    # Invalid
    output=""
fi

# EC RBP Key Revoke state
echo $output
}

# HMC-NVSWITCH_EROT-Key-08
# Function to get AP RBP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP RBP key revoke state
get_nvswitch_erot_ap_rbp_key_revoke_state_vdm() {
local nvswitch_erot_eid="$1"
local eid
local response
local output
# default 15 to NVSWITCH ERoT EID
eid=${nvswitch_erot_eid:-15} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:19:16}
else
    # Invalid
    output=""
fi

# AP RBP Key Revoke state
echo $output
}

# HMC-NVSWITCH_EROT-Security-01
# Function to get EC background copy progress state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC background copy progress state
get_nvswitch_erot_background_copy_progress_state_vdm() {
local nvswitch_erot_eid="$1"
local eid
local response
local output
# default 17 to FPGA ERoT EID
eid=${nvswitch_erot_eid:-15} && response=($(_log_ mctp-vdm-util -t ${eid} -c background_copy_query_progress | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-11))

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[1]}
else
    # Invalid
    output=""
fi

case $output in
01) echo "copy not in progress";;
02) echo "copy in progress";;
*) echo "unknown";;
esac
}


## PEXSW: Transport Protocol

# HMC-PEXSW-VFIO_SMBPBI-01
# Function to get PEXSW FW version through VFIO SMBPBI Proxy
# Arguments:
#   $1: Software ID
# Returns:
#   valid GPU version
get_pcieswitch_version_vfio_smbpbi_proxy() {
local sw_id="$1"
id=${sw_id:-HGX_FW_PCIeSwitch_0} && _log_ busctl get-property xyz.openbmc_project.GpuMgr /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-PEXSW-I2C_SMBPBI-01
# Function to get PEXSW FW version through SMBPBI on I2C-3 bus
# Arguments:
#   $1: I2C Bus number for the BMC I2C-3 (i2c 2)
#   $2: I2C Addr for the PEXSW SMBPBI server
#   $3: Register Addr for the target component
# Returns:
#   valid PEXSW FW version
get_pcieswitch_version_i2c_smbpbi() {
local i2c_bus="$1"
local i2c_addr="$2"
local register="$3"
local output
bus=${i2c_bus:-3} && addr=${i2c_addr:-0x8} && reg=${register:-0xa0} && output=$(_log_ i2ctransfer -f -y "$bus" w6@"$addr" 0x5c 0x04 0x05 "$reg" 0x00 0x80; i2ctransfer -f -y "$bus" w1@"$addr" 0x5d r14 | cut -d ' ' -f 2-6) && echo "$output"
}

# HMC-PEXSW_EROT-MCTP_VDM-01
# Function to get the enumrated MCTP EID, PEXSW ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid "19"
get_pcieswitch_erot_mctp_eid_spi() {
local pexsw_erot_spi_eid="$1"

# default EID to 19, PEXSW MCTP ERoT SPI
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${pexsw_erot_spi_eid:-19} && mctp_call='_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1' && eid_rt=$(eval " $mctp_call" 2>&1 | grep mctp_resp_msg | cut -d ' ' -f 8) && printf '%d\n' 0x$eid_rt
}

# HMC-PEXSW_EROT-MCTP_VDM-02
# Function to get the enumrated MCTP EID, PEXSW ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the EID to get from
# Returns:
#   valid "25"
get_pcieswitch_erot_mctp_eid_i2c() {
local pexsw_erot_i2c_eid="$1"

# default EID to 25, Nero PEXSW MCTP ERoT I2C
# get MCTP EID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${pexsw_erot_i2c_eid:-25} && mctp_call='_log_ mctp-pcie-ctrl -s "00 80 02" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1' && eid_rt=$(eval " $mctp_call" 2>&1 | grep mctp_resp_msg | cut -d ' ' -f 8) && printf '%d\n' 0x$eid_rt
}

# HMC-PEXSW_EROT-MCTP_VDM-03
# Function to get the MCTP UUID for PEXSW ERoT SPI
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_pcieswitch_erot_mctp_uuid_spi() {
local pexsw_erot_spi_eid="$1"

# default EID to 19, PEXSW MCTP ERoT SPI
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${pexsw_erot_spi_eid:-19} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

# HMC-PEXSW_EROT-MCTP_VDM-04
# Function to get the MCTP UUID for PEXSW ERoT I2C
# Arguments:
#   $1: MCTP EID to verify the UUID to get from
# Returns:
#   valid UUID according to FPGA IAS
get_pcieswitch_erot_mctp_uuid_i2c() {
local pexsw_erot_i2c_eid="$1"

# default EID to 25, PEXSW MCTP ERoT I2C
# get MCTP UUID
# the 'mctp-pcie-ctrl -v 1' outputs 'mctp_resp_msg' to stderr
eid=${pexsw_erot_i2c_eid:-25} && uuid_rt=$(_log_ mctp-pcie-ctrl -s "00 80 03" -t 2 -b "02 00 00 00 00 01" -e "${eid}" -i 9 -p 12 -x 13 -m 0 -v 1 | grep mctp_resp_msg | sed 's/.*mctp_resp_msg.*> //' | cut -d ' ' -f 5-) && echo $uuid_rt
}

# HMC-PEXSW_EROT-DBUS-13
# Function to get PEXSW ERoT-SPI MCTP UUID via MCTP over VDM through DBus
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid MCTP UUID
get_pcieswitch_dbus_mctp_vdm_spi_uuid() {
local eid="$1"
local output

# default EID to 19, PEXSW ERoT via MCTP over VDM
erot_id=${eid:-19} && output=$(_log_ busctl introspect xyz.openbmc_project.MCTP.Control.PCIe /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

# HMC-PEXSW_EROT-DBUS-14
# Function to get PEXSW ERoT-I2C MCTP UUID via MCTP over VDM through DBus
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid MCTP UUID
get_pcieswitch_dbus_mctp_vdm_i2c_uuid() {
local eid="$1"
local output

# default EID to 25, PEXSW ERoT via MCTP over VDM
erot_id=${eid:-25} && output=$(_log_ busctl introspect xyz.openbmc_project.MCTP.Control.PCIe /xyz/openbmc_project/mctp/0/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

## PEXSW: Base Protocol

# HMC-PEXSW_EROT-PLDM_T0-01
# Function to get PLDM base GetTID of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid TID
get_pcieswitch_erot_pldm_tid() {
local pexsw_eid="$1"
eid=${pexsw_eid:-19} && output=$(_log_ pldmtool base GetTID -m "$eid" | grep -o -e 'TID.*' | cut -d ':' -f 2 | tr -d ' ') && echo $output
}

# HMC-PEXSW_EROT-PLDM_T0-02
# Function to get PLDM base GetPLDMTypes of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Types
get_pcieswitch_erot_pldm_pldmtypes() {
local pexsw_eid="$1"
eid=${pexsw_eid:-25} && output=$(_log_ pldmtool base GetPLDMTypes -m "$eid" | grep -o 'PLDM Type Code.*' | cut -d ':' -f 2 | tr -d ' '); echo $output
}

# HMC-PEXSW_EROT-PLDM_T0-03
# Function to get PLDM base GetPLDMVersion T0 of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_pcieswitch_erot_pldm_t0_pldmversion() {
local pexsw_eid="$1"
eid=${pexsw_eid:-25} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 0 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

# HMC-PEXSW_EROT-PLDM_T0-04
# Function to get PLDM base GetPLDMVersion T5 of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid PLDM Version
get_pcieswitch_erot_pldm_t5_pldmversion() {
local pexsw_eid="$1"
eid=${pexsw_eid:-25} && output=$(_log_ pldmtool base GetPLDMVersion -m "$eid" -t 5 | grep -o -e 'Response.*' | cut -d ':' -f 2 | tr -d ' "') && echo $output
}

## PEXSW: Firmware Update Protocol

# HMC-PEXSW_EROT-Version-01
# Function to get PEXSW ERoT FW version from PLDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_pcieswitch_erot_fw_version_pldm() {
local eid="$1"
local output
# default EID to 25, PEXSW ERoT
eid=${eid:-25} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-PEXSW_EROT-Version-02
# Function to get PEXSW ERoT FW version from PLDM dbus
# Arguments:
#   $1: Software ID
# Returns:
#   valid ERoT FW version
get_pcieswitch_erot_fw_version_pldm_dbus() {
local sw_id="$1"
id=${sw_id:-HGX_FW_ERoT_PCIeSwitch_0} && _log_ busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$id" xyz.openbmc_project.Software.Version Version | cut -d ' ' -f 2 | tr -d '"'
}

# HMC-PEXSW_EROT-Version-03
# Function to get PEXSW ERoT FW Build Type
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Build Type
get_pcieswitch_erot_fw_build_type() {
local pexsw_erot_eid="$1"
# default 25 to PEXSW ERoT EID
# 0: rel, 1: dev
eid=${pexsw_erot_eid:-25} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

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

# HMC-PEXSW_EROT-Version-04
# Function to get PEXSW ERoT FW Keyset
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Keyset
get_pcieswitch_erot_fw_keyset() {
local pexsw_erot_eid="$1"
# default 25 to PEXSW ERoT EID
# 0: s1, 1: s2, 2: s3, 3: s4, 4: s5
eid=${pexsw_erot_eid:-25} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

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

# HMC-PEXSW_EROT-Version-05
# Function to get PEXSW ERoT FW Chip Rev
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Chip Rev
get_pcieswitch_erot_fw_chiprev() {
local pexsw_erot_eid="$1"
# default 25 to PEXSW ERoT EID
# 0: revA, 1:revB
eid=${pexsw_erot_eid:-25} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

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

# HMC-PEXSW_EROT-Version-06
# Function to get PEXSW ERoT FW Boot Slot
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Boot Slot
get_pcieswitch_erot_fw_boot_slot() {
local pexsw_erot_eid="$1"
# default 25 to PEXSW ERoT EID
eid=${pexsw_erot_eid:-25} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

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

# HMC-PEXSW_EROT-Version-07
# Function to get PEXSW ERoT FW EC Identical
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW EC Identical
get_pcieswitch_erot_fw_ec_identical() {
local pexsw_erot_eid="$1"
# default 25 to PEXSW ERoT EID
# 0: identical, 1: not identical
eid=${pexsw_erot_eid:-25} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

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

# HMC-PEXSW_EROT-PLDM_T5-01
# Function to get PLDM fw_update version of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_pcieswitch_erot_pldm_version() {
local eid="$1"
# default EID to 25, PEXSW ERoT
eid=${eid:-25} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-PEXSW_EROT-PLDM_T5-02
# Function to get PLDM fw_update version of PEXSW
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid FW version
get_pcieswitch_erot_pldm_version_string() {
local eid="$1"
# default EID to 25, PEXSW ERoT
eid=${eid:-25} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==2') && echo $output
}

# HMC-PEXSW_EROT-PLDM_T5-05
# Function to get PLDM fw_update AP_SKU ID of PEXSW
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_pcieswitch_erot_pldm_apsku_id() {
local sku_eid="$1"
# default EID to 25, PEXSW ERoT
eid=${sku_eid:-25} && key=${sku_key:-APSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-PEXSW_EROT-PLDM_T5-06
# Function to get PLDM fw_update EC_SKU ID of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC_SKU ID
get_pcieswitch_erot_pldm_ecsku_id() {
local sku_eid="$1"
# default EID to 25, PEXSW ERoT
eid=${sku_eid:-25} && key=${sku_key:-ECSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-PEXSW_EROT-PLDM_T5-07
# Function to get PLDM fw_update GLACIERDSD of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid GLACIERDSD ID
get_pcieswitch_erot_pldm_glacier_id() {
local sku_eid="$1"
# default EID to 25, PEXSW ERoT
eid=${sku_eid:-25} && key=${sku_key:-GLACIERDSD} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-PEXSW_EROT-DBUS-03
# Function to get PLDM DBus chassis inventory UUID of PEXSW ERoT
# Arguments:
#   $1: PLDM Inventory ID
# Returns:
#   valid MCTP UUID
get_pcieswitch_dbus_pldm_hmc_erot_uuid() {
local pexsw_pldm_erot_id="$1"
erot_id=${pexsw_pldm_erot_id:-HGX_ERoT_PCIeSwitch_0} && output=$(_log_ busctl introspect xyz.openbmc_project.PLDM /xyz/openbmc_project/inventory/system/chassis/"$erot_id" | grep '.UUID' | grep -o '"[^"]*"' | tr -d '"') && echo $output
}

# HMC-PEXSW_EROT-PLDM_T5-08
# Function to get PLDM fw_update PCI Vendor ID of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Vendor" ID
get_pcieswitch_erot_pldm_pci_vendor_id() {
local sku_eid="$1"
# default EID to 19, PCIESWITCH #1 SPI ERoT
eid=${sku_eid:-19} && key=${sku_key:-"PCI Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-PCIESWITCH_EROT-PLDM_T5-09
# Function to get PLDM fw_update PCI Device ID of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Device" ID
get_pcieswitch_erot_pldm_pci_device_id() {
local sku_eid="$1"
# default EID to 19, PCIESWITCH #1 SPI ERoT
eid=${sku_eid:-19} && key=${sku_key:-"PCI Device ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-PCIESWITCH_EROT-PLDM_T5-10
# Function to get PLDM fw_update Subsystem Vendor ID of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem Vendor" ID
get_pcieswitch_erot_pldm_pci_subsys_vendor_id() {
local sku_eid="$1"
# default EID to 19, PCIESWITCH #1 SPI ERoT
eid=${sku_eid:-19} && key=${sku_key:-"PCI Subsystem Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-PCIESWITCH_EROT-PLDM_T5-11
# Function to get PLDM fw_update Subsystem ID of PEXSW ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem" ID
get_pcieswitch_erot_pldm_pci_subsys_id() {
local sku_eid="$1"
# default EID to 19, PCIESWITCH #1 SPI ERoT
eid=${sku_eid:-19} && key=${sku_key:-"PCI Subsystem ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

## PEXSW: Security Protocol

# HMC-PEXSW_EROT-Security-01
# Function to get EC background copy progress state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC background copy progress state
get_pcieswitch_erot_background_copy_progress_state_vdm() {
local pcieswitch_erot_eid="$1"
local eid
local response
local output
# default 19 to PEXSW ERoT EID
eid=${pcieswitch_erot_eid:-19} && response=($(_log_ mctp-vdm-util -t ${eid} -c background_copy_query_progress | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-11))

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[1]}
else
    # Invalid
    output=""
fi

case $output in
01) echo "copy not in progress";;
02) echo "copy in progress";;
*) echo "unknown";;
esac
}

# HMC-PEXSW_EROT-SPDM-01
# Function to get SPDM Version through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Version
get_pcieswitch_erot_spdm_version() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_PCIeSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Version | cut -d ' ' -f 2) && echo $output
}

# HMC-PEXSW_EROT-SPDM-02
# Function to get SPDM Measurements Type through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Measurements Type
get_pcieswitch_erot_spdm_measurements_type() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_PCIeSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder MeasurementsType | tr -d '"' | cut -d '.' -f 6) && echo $output
}

# HMC-PEXSW_EROT-SPDM-03
# Function to get SPDM Algorithms through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Algorithms
get_pcieswitch_erot_spdm_hash_algorithms() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_PCIeSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder HashingAlgorithm | cut -d ' ' -f 2 | cut -d '.' -f 6 | tr -d '"')
id=${spdm_id:-'HGX_ERoT_PCIeSwitch_0'} && output+=" $(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder SigningAlgorithm | cut -d ' ' -f 2 | cut -d '.' -f 6 | tr -d '"')"
echo "$output"
}

# HMC-PEXSW_EROT-SPDM-04
# Function to get SPDM Measurement of Serial Number (index 27)
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid "yes", "no" otherwise
get_pcieswitch_erot_spdm_measurement_serial_number() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_PCIeSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Measurements) && [[ -n $output ]] && echo "yes" || echo "no"
}

# HMC-PEXSW_EROT-SPDM-05
# Function to get SPDM Measurement of Token Request (index 50)
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid "yes", "no" otherwise
get_pcieswitch_erot_spdm_measurement_token_request() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_PCIeSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Measurements) && [[ -n $output ]] && echo "okay" || echo "no"
}

# HMC-PEXSW_EROT-SPDM-06
# Function to get SPDM Certificate count through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Certificate count
get_pcieswitch_erot_spdm_certificate_count() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_PCIeSwitch_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Certificate | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $output
}

# HMC-PEXSW_EROT-Key-01
# Function to get EC key revoke policy via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid revoke policy
get_pcieswitch_erot_key_revoke_policy_i2c() {
local i2c_addr="${1:-0x3e}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke policy", cmd=0x1d, arg=0x00, read length=20
response=$(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x1d 0x00 20)

output=${response:90:4}

case $output in
0x00) echo "not set";;
0x01) echo "auto";;
0x02) echo "decoupled";;
*) echo "unknown";;
esac
}

# HMC-PEXSW_EROT-Key-03
# Function to get EC key revoke state via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid EC key revoke state
get_pcieswitch_erot_ec_key_revoke_state_i2c() {
local i2c_addr="${1:-0x3e}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke", selftest cmd=0x08, arg=0x08, read length=61
response=($(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x08 0x08 61))

# EC Key Revoke state
echo ${response[35]}
}

# HMC-PEXSW_EROT-Key-04
# Function to get EC key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_pcieswitch_erot_ec_key_revoke_state_vdm() {
local pcieswitch_erot_eid="$1"
local eid
local response
local output
# default 19 to PEXSW ERoT EID
eid=${pcieswitch_erot_eid:-19} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[18]}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-PEXSW_EROT-Key-06
# Function to get AP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_pcieswitch_erot_ap_key_revoke_state_vdm() {
local pcieswitch_erot_eid="$1"
local eid
local response
local output
# default 19 to PCIESWITCH ERoT EID
eid=${pcieswitch_erot_eid:-19} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:35:8}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-PEXSW_EROT-Key-05
# Function to get AP key revoke state via I2C
# Arguments:
#   $1: I2C Bus
#   $2: EROT I2C Address
#   $3: DEST I2C Address
#   $4: FPGA SMBPBI I2C Address
# Returns:
#   valid EC key revoke state
get_pcieswitch_erot_ap_key_revoke_state_i2c() {
local i2c_addr="${1:-0x3e}"
local i2c_addr_dest="${2:-0x52}"
local i2c_addr_fpga_smbpbi="${3:-0x60}"
local i2c_bus="${4:-0}"
local response
local output

_log_ echo ${FUNCNAME[0]} >/dev/null
# query "key revoke", selftest cmd=0x08, arg=0x08, read length=61
response=($(_ec_send_message $i2c_bus $i2c_addr $i2c_addr_dest $i2c_addr_fpga_smbpbi 0x08 0x08 61))

# AP Key Revoke state
output=${response[@]:52:8}
echo $output
}

# HMC-CPU_EROT-Version-01
# Function to get CPU ERoT FW version from PLDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW version
get_cpu_erot_fw_version_pldm() {
local eid="$1"
local output
# default EID to 16, CPU ERoT
eid=${eid:-16} && output=$(_log_ pldmtool fw_update GetFWParams -m "$eid" | grep 'ActiveComponentVersionString' | sed 's/.*"\(.*\)".*/\1/' | awk 'NR==1') && echo $output
}

# HMC-CPU_EROT-PLDM_T5-05
# Function to get PLDM fw_update AP_SKU ID of CPU
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid AP_SKU ID
get_cpu_erot_pldm_apsku_id() {
local sku_eid="$1"
# default EID to 16, CPU ERoT
eid=${sku_eid:-16} && key=${sku_key:-APSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-CPU_EROT-PLDM_T5-06
# Function to get PLDM fw_update EC_SKU ID of CPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC_SKU ID
get_cpu_erot_pldm_ecsku_id() {
local sku_eid="$1"
# default EID to 16, CPU ERoT
eid=${sku_eid:-16} && key=${sku_key:-ECSKU} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-CPU_EROT-PLDM_T5-07
# Function to get PLDM fw_update GLACIERDSD of CPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid GLACIERDSD ID
get_cpu_erot_pldm_glacier_id() {
local sku_eid="$1"
local output
# default EID to 16, CPU ERoT
eid=${sku_eid:-16} && key=${sku_key:-GLACIERDSD} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -o "\"$key\": [^,]*" | sed -e "s/\"$key\": //" -e 's/"//g') && echo $output
}

# HMC-CPU_EROT-PLDM_T5-08
# Function to get PLDM fw_update PCI Vendor ID of CPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Vendor" ID
get_cpu_erot_pldm_pci_vendor_id() {
local sku_eid="$1"
# default EID to 16, CPU ERoT
eid=${sku_eid:-16} && key=${sku_key:-"PCI Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-CPU_EROT-PLDM_T5-09
# Function to get PLDM fw_update PCI Deivce ID of CPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Device" ID
get_cpu_erot_pldm_pci_device_id() {
local sku_eid="$1"
# default EID to 16, CPU ERoT
eid=${sku_eid:-16} && key=${sku_key:-"PCI Device ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-CPU_EROT-PLDM_T5-10
# Function to get PLDM fw_update PCI Subsystem Vendor ID of CPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem Vendor" ID
get_cpu_erot_pldm_pci_subsys_vendor_id() {
local sku_eid="$1"
# default EID to 16, CPU ERoT
eid=${sku_eid:-16} && key=${sku_key:-"PCI Subsystem Vendor ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-CPU_EROT-PLDM_T5-11
# Function to get PLDM fw_update PCI Subsystem ID of CPU ERoT
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid "PCI Subsystem" ID
get_cpu_erot_pldm_pci_subsys_id() {
local sku_eid="$1"
# default EID to 16, CPU ERoT
eid=${sku_eid:-16} && key=${sku_key:-"PCI Subsystem ID"} && output=$(_log_ pldmtool fw_update QueryDeviceIdentifiers -m "$eid" | grep -A3 "${key}" | awk '/"Value"/ {getline; print $1}') && echo ${output//\"}
}

# HMC-CPU_EROT-SPDM-06
# Function to get SPDM Certificate count through DBus
# Arguments:
#   $1: SPDM ID
# Returns:
#   valid SPDM Certificate count
get_cpu_erot_spdm_certificate_count() {
local spdm_id="$1"
id=${spdm_id:-'HGX_ERoT_CPU_0'} && output=$(_log_ busctl get-property xyz.openbmc_project.SPDM /xyz/openbmc_project/SPDM/"$id" xyz.openbmc_project.SPDM.Responder Certificate | grep -o 'BEGIN CERTIFICATE' | wc -l) && echo $output
}

# HMC-CPU_EROT-Key-04
# Function to get EC key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_cpu_erot_ec_key_revoke_state_vdm() {
local cpu_erot_eid="$1"
local eid
local response
local output
# default 16 to CPU ERoT EID
eid=${cpu_erot_eid:-16} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[18]}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-CPU_EROT-Key-06
# Function to get AP key revoke state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC key revoke state
get_cpu_erot_ap_key_revoke_state_vdm() {
local cpu_erot_eid="$1"
local eid
local response
local output
# default 13 to CPU ERoT EID
eid=${cpu_erot_eid:-15} && response=($(_log_ mctp-vdm-util -t ${eid} -c selftest 8 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-61))

# older EC FW does not support the selftest
if [ ${#response[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
fi

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[@]:35:8}
else
    # Invalid
    output=""
fi

# EC Key Revoke state
echo $output
}

# HMC-CPU_EROT-Version-04
# Function to get CPU ERoT FW Keyset
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Keyset
get_cpu_erot_fw_keyset() {
local cpu_erot_eid="$1"
# default 16 to CPU ERoT EID
# 0: s1, 1: s2, 2: s3, 3: s4, 4: s5, 5: s6
eid=${cpu_erot_eid:-16} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
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

# HMC-CPU_EROT-Version-05
# Function to get CPU ERoT FW Chip Rev
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Chip Rev
get_cpu_erot_fw_chiprev() {
local cpu_erot_eid="$1"
# default 16 to CPU ERoT EID
# 0: revA, 1:revB
eid=${cpu_erot_eid:-16} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
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

# HMC-CPU_EROT-Version-03
# Function to get CPU ERoT FW Build Type
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid ERoT FW Build Type
get_cpu_erot_fw_build_type() {
local cpu_erot_eid="$1"
# default 14 to CPU ERoT EID
# 0: rel, 1: dev
eid=${cpu_erot_eid:-16} && output=($(_log_ mctp-vdm-util -t ${eid} -c selftest 2 0 0 0 | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-18))

# older EC FW does not support the selftest
if [ ${#output[@]} -lt 9 ]; then
    # Invalid
    echo ""
    return 1
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

# HMC-CPU_EROT-Security-01
# Function to get EC background copy progress state via VDM
# Arguments:
#   $1: MCTP EID
# Returns:
#   valid EC background copy progress state
get_cpu_erot_background_copy_progress_state_vdm() {
local cpu_erot_eid="$1"
local eid
local response
local output
# default 15 to CPU ERoT EID
eid=${cpu_erot_eid:-15} && response=($(_log_ mctp-vdm-util -t ${eid} -c background_copy_query_progress | grep -o 'RX: [0-9a-fA-F ]*' | sed 's/RX: //' | cut -d ' ' -f 9-11))

# completion code="00", successful
if [[ "${response[0]}" == "00" ]]; then
    output=${response[1]}
else
    # Invalid
    output=""
fi

case $output in
01) echo "copy not in progress";;
02) echo "copy in progress";;
*) echo "unknown";;
esac
}

# BMC-CPLD_JTAG-Version-01
# Function to get JTAG bus status
# Arguments:
#   $1: JTAG bus number
#   $2: CPLD setup file location
#   $3: JTAG ID decode
#   $3: Number of expected CPLDs
# Returns:
#   Number of devices found
get_bmc_jtag_bus_state() {
local jtag_bus_num="$1"
local jtag_setupfile="$2"
local id_decode="$3"
local num_cpld="$4"
local response
local output

setup=${jtag_setupfile:-"/usr/bin/setup_vme.sh"}
setup_res=$($setup)
if [[ "$?" == "1" ]]; then
    echo "Setup Failed: Ensure RUN_POWER is on and JTAG GPIO is asserted"
fi

bus=${jtag_bus_num:-"1"} && id=${id_decode:-"0x12bc043"} && num=${num_cpld:-"4"} && \
response=($(_log_ /usr/bin/jtag_test -j /dev/jtag${bus} -v -i ${id} | grep 'Found number of devices' | cut -d ':' -f 2))

if [[ -n "${response}" && "$response" -gt "0" ]]; then
    echo "${response}"
else
    # Invalid
    echo ""
fi
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


export hmc_checker_version="0.04.00-08262024"
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

skip_keywords=("cx7" "spdm" "gpu" "nvswitch")
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
