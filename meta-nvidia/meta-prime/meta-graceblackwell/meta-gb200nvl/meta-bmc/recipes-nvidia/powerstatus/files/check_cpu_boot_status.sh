#!/bin/sh

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

# Get platform variables
source /etc/default/platform_var.conf

fruDeviceCommand="dbus-send --system --print-reply \
                  --dest=xyz.openbmc_project.ObjectMapper \
                  /xyz/openbmc_project/object_mapper \
                  xyz.openbmc_project.ObjectMapper.GetSubTreePaths \
                  string:'/xyz/openbmc_project/FruDevice/' \
                  int32:0 array:string:'xyz.openbmc_project.FruDevice' | grep -o 'string \".*\"' | cut -d' ' -f2 | sed 's/\"//g'"

function getDbusProperty()
{
    objpath=$1
    property=$2
    busctl get-property xyz.openbmc_project.FruDevice \
        ${objpath} \
        xyz.openbmc_project.FruDevice \
        ${property} 2>/dev/null | awk -F'"' '{print $2}'
}

function pingFruDevice()
{
    local counter=0
    while [ ${counter} -lt 60 ]; do
        if [ -n "$(eval ${fruDeviceCommand})" ]; then
            return 0
        fi
        ((counter++))
        sleep 1
    done
    return 1
}

# Test if FruDevice is ready
if ! pingFruDevice; then
    echo "Failed to find a fru to check SKU"
    exit 1
fi

# If FruDevice has data, wait 3s to make sure all frus are ready
sleep 3

cpu_info_board_list="P4975\|P5859"

# Initialize CPU count and targets based on product name
while read -r line; do
    if echo "$line" | grep -qi "${cpu_info_board_list}"; then
        product_name=$(getDbusProperty "$line" "PRODUCT_PRODUCT_NAME")
        case "$product_name" in
            *Bianca*) cpu_count=2 ;;
            *Ariel*) cpu_count=2 ;;
            *"Super Ariel"*) cpu_count=4 ;;
            *) cpu_count=1 ;;
        esac

        echo "Get the SKU name = ${product_name} with ${cpu_count} CPU Sockets"

        # Adjust CPU checked targets based on cpu_count
        targets=()
        for ((i=0; i<cpu_count; i++)); do
            # It is the post code of EFI_NV_FW_BOOT_PC_BPMP_FW_READY
            # Following is the detailed info
            # Byte 7 = 0x01 = Progress Code
            # Byte 10 – Severity = 0x00 = Unspecified
            # Byte 11 – Byte 12 = 0x0009 = EFI_NV_FW_BOOT_PC_BPMP_FW_READY
            # Byte 13 – 0x01 = Progress
            # Byte 14 – Class = 0xC1 = NVIDIA Firmware
            # Byte 15 = Instance, 0x00 = Socket 0, 0x40 = Socket 1,
            #                    0x80 = Socket 2, 0xC0 = Socket 3
            targets+=("[1,0,0,0,9,0,1,193,$((i*64))]")
        done
    fi
done <<< "$(eval ${fruDeviceCommand})"

# Initialize found_targets array to track found CPU post codes
found_targets=()
for target in "${targets[@]}"; do
    found_targets+=(false)
done

# Function to check all CPU boot post codes
check_all_cpu_boot_post_code() {
    trycnt=1
    until [[ $trycnt -gt 60 ]]; do
        # Get the current BootCycleCount
        boot_cycle_count=$(busctl get-property xyz.openbmc_project.State.Boot.PostCode0 /xyz/openbmc_project/State/Boot/PostCode0 xyz.openbmc_project.State.Boot.PostCode CurrentBootCycleCount | awk '{print $2}')

        # Command to retrieve post codes
        get_post_code_command="busctl call xyz.openbmc_project.State.Boot.PostCode0 /xyz/openbmc_project/State/Boot/PostCode0 xyz.openbmc_project.State.Boot.PostCode GetPostCodes q $boot_cycle_count -j"

        # Execute the command and capture output
        output=$($get_post_code_command)

        # Extract the arrays from the JSON output
        IFS=$'\n' read -r -d '' -a arrays < <(echo "$output" | grep -o '\[[0-9,]\+\]')

        # Reset found count
        found_count=0
        for array in "${arrays[@]}"; do
            for i in "${!targets[@]}"; do
                if [ "$array" == "${targets[$i]}" ]; then
                    found_targets[$i]=true
                    ((found_count++))
                fi
            done
        done

        # Check if all CPU post codes are found
        if [ $found_count -eq $cpu_count ]; then
            # all CPU post codes are found, exit
            exit 0
        else
            sleep 1
        fi

        ((trycnt++))
    done
}

# Check for all CPU target arrays
check_all_cpu_boot_post_code

# Report any missing CPU boot post codes as errors
for i in "${!found_targets[@]}"; do
    if [ "${found_targets[$i]}" == "false" ]; then
        msg="CPU Socket $i,Boot Failure"
        resolution="Ensure the CPU socket is connected and seated. Replace the defective CPU socket if necessary."
        originofcondition="/redfish/v1/Chassis/HGX_CPU_$i"
        busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} \
            ResourceEvent.1.0.ResourceErrorsDetected xyz.openbmc_project.Logging.Entry.Level.Error 4 \
            REDFISH_MESSAGE_ID ResourceEvent.1.0.ResourceErrorsDetected \
            REDFISH_MESSAGE_ARGS "$msg" \
            REDFISH_ORIGIN_OF_CONDITION "$originofcondition" \
            xyz.openbmc_project.Logging.Entry.Resolution "$resolution"
    fi
done
