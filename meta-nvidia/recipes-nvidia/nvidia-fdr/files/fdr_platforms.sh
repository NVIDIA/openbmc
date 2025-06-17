#!/bin/bash

# Paths
TMP_DIR="/tmp/nvidia-fdr/platforms"
PLATFORM_DIR="/etc/nvidia-fdr/platforms"

# Logging helper
log_to_journal() {
    echo "$1" | systemd-cat -t nvidia-fdr-script
}

# Step 1: Clean /tmp/nvidia-fdr/platforms
clean_tmp_directory() {
    if [ -d "$TMP_DIR" ]; then
        if [ "$(ls -A $TMP_DIR)" ]; then
            rm -rf "$TMP_DIR"/*
            log_to_journal "Cleaned /tmp/nvidia-fdr/platforms directory."
        else
            log_to_journal "/tmp/nvidia-fdr/platforms is already empty."
        fi
    else
        mkdir -p "$TMP_DIR"
        log_to_journal "Created /tmp/nvidia-fdr/platforms directory."
    fi
}

# Step 2: Check /etc/nvidia-fdr/platforms for files
check_and_extract_single_file() {
    if [ -d "$PLATFORM_DIR" ]; then
        files=("$PLATFORM_DIR"/*)
        file_count=${#files[@]}

        if [ "$file_count" -eq 1 ]; then
            log_to_journal "Only one platform file found. Extracting: ${files[0]}"
            tar --strip-components=1 -xf "${files[0]}" -C "$TMP_DIR/" || { log_to_journal "Failed to extract ${files[0]}."; exit 1; }
            exit 0  # Exit as we don't need further steps
        elif [ "$file_count" -gt 1 ]; then
            log_to_journal "Multiple platform files found in /etc/nvidia-fdr/platforms."
        else
            log_to_journal "No platform files found in /etc/nvidia-fdr/platforms."
            exit 1
        fi
    else
        log_to_journal "/etc/nvidia-fdr/platforms does not exist."
        exit 1
    fi
}

# Step 3: Get obj-path for FRU FDR config.
get_fdr_obj_path() {
    local start_time=$(date +%s)
    local max_duration=$((5 * 60))  # 5 minutes in seconds
    local interval=10

    while true; do
        obj_path=$(dbus-send --system --print-reply \
            --dest=xyz.openbmc_project.ObjectMapper \
            /xyz/openbmc_project/object_mapper \
            xyz.openbmc_project.ObjectMapper.GetSubTreePaths \
            string:"/" int32:0 array:string:"xyz.openbmc_project.Configuration.NvidiaFlightDataRecorder" \
            | grep "string" | head -n 1 | awk '{print $2}' | tr -d '"')
        
        if [ -n "$obj_path" ]; then
            log_to_journal "Selected object path: $obj_path"
            echo "$obj_path"
            return 0
        fi

        elapsed_time=$(( $(date +%s) - start_time ))
        if [ $elapsed_time -ge $max_duration ]; then
            log_to_journal "WARNING: Timeout reached while waiting for object path. Using default YAML."
            echo ""
            return 1
        fi

        sleep $interval
    done
}

# Get default YAML file from platform directory
get_default_yaml() {
    # Look for *_def.yaml first
    default_file=$(find "$PLATFORM_DIR" -maxdepth 1 -type f -name "*_def.yaml" | head -n 1)

    if [ -n "$default_file" ]; then
        log_to_journal "Found default YAML file: $(basename "$default_file")"
        echo "$(basename "$default_file")"
        return
    fi

    # If no *_def.yaml found, find any .yaml file
    smallest_file=$(find "$PLATFORM_DIR" -maxdepth 1 -type f -name "*.yaml" | head -n 1)

    if [ -n "$smallest_file" ]; then
        log_to_journal "No *_def.yaml found, using first available YAML file: $(basename "$smallest_file")"
        echo "$(basename "$smallest_file")"
        return
    fi

    # If still no file, log error and exit
    log_to_journal "ERROR: No YAML files found in $PLATFORM_DIR"
    exit 1
}


# Step 4: Get the YAML file name
get_yaml_filename() {
    obj_path="$1"

    if [ -z "$obj_path" ]; then
        default_yaml=$(get_default_yaml)
        log_to_journal "Using default YAML file: $default_yaml"
        echo "$default_yaml"
        return
    fi

    output=$(busctl get-property xyz.openbmc_project.EntityManager "$obj_path" xyz.openbmc_project.Configuration.NvidiaFlightDataRecorder Model 2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$output" ]; then
        default_yaml=$(get_default_yaml)
        log_to_journal "ERROR: Failed to get YAML filename. Using default YAML: $default_yaml"
        echo "$default_yaml"
        return
    fi

    yaml_file=$(echo "$output" | awk -F'"' '{print $2}')

    # Check if yaml_file exists in PLATFORM_DIR
    found_file=$(find "$PLATFORM_DIR" -maxdepth 1 -type f -name "*${yaml_file}*" | head -n 1)
    
    if [ -z "$found_file" ]; then
        log_to_journal "WARNING: No file containing '$yaml_file' found in $PLATFORM_DIR. Using default YAML."
        default_yaml=$(get_default_yaml)
        echo "$default_yaml"
        return
    fi
    
    # Get the actual filename from found path
    yaml_file=$(basename "$found_file")
    log_to_journal "Found matching YAML file: $yaml_file"
    echo "$yaml_file"
}

# Step 5: Extract YAML file
select_and_extract_file() {
    yaml_file="$1"
    file=$(find "$PLATFORM_DIR" -maxdepth 1 -type f -name "$yaml_file" | head -n 1)

    if [ -z "$file" ]; then
        log_to_journal "ERROR: No matching platform file found for $yaml_file."
        exit 1
    fi

    tar --strip-components=1 -xf "$file" -C "$TMP_DIR/" && log_to_journal "SUCCESS: Extracted $file to $TMP_DIR." || { log_to_journal "ERROR: Failed to extract $file."; exit 1; }
}

# Step 6: Wait for HMC Ready
check_hmcready() {
    local start_time=$(date +%s)
    local max_duration=$((5 * 60))  # 5 minutes in seconds
    local interval=10
    local remaining_time=0

    # Calculate remaining time from get_fdr_obj_path
    if [ -n "$1" ]; then
        elapsed_time=$(( $(date +%s) - $1 ))
        remaining_time=$(( max_duration - elapsed_time ))
        if [ $remaining_time -le 0 ]; then
            log_to_journal "No time remaining for HMC ready check after object path wait"
            return 0
        fi
    fi

    CMD="busctl get-property xyz.openbmc_project.State.ConfigurableStateManager /xyz/openbmc_project/state/configurableStateManager/Manager xyz.openbmc_project.State.FeatureReady State"
    DESIRED_OUTPUT='s "xyz.openbmc_project.State.FeatureReady.States.Enabled"'

    while true; do
        OUTPUT=$(eval "$CMD")

        if [[ "$OUTPUT" == "$DESIRED_OUTPUT" ]]; then
            log_to_journal "HMC Ready: $OUTPUT"
            return 0
        fi

        elapsed_time=$(( $(date +%s) - start_time ))
        if [ $elapsed_time -ge $remaining_time ]; then
            log_to_journal "Timeout reached for HMC ready check. Current state: $OUTPUT"
            return 0
        fi

        sleep $interval
    done
}

main() {
    clean_tmp_directory                                 # Step 1: Prepare the temporary directory
    check_and_extract_single_file                       # Step 2: Handle single file case or continue
    start_time=$(date +%s)                             # Record start time for combined timeout
    obj_path=$(get_fdr_obj_path)                        # Step 3: Get obj-path for FRU FDR config
    yaml_file=$(get_yaml_filename "$obj_path")          # Step 4: Get the YAML file name
    select_and_extract_file "$yaml_file"                # Step 5: Extract YAML file
}

main