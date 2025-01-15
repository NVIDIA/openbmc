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
    # Check if the platform directory exists and contains files
    if [ -d "$PLATFORM_DIR" ]; then
        files=("$PLATFORM_DIR"/*)  # Store all files in an array
        file_count=${#files[@]}   # Get the count of files

        if [ "$file_count" -eq 1 ]; then
            log_to_journal "Only one platform file found in /etc/nvidia-fdr/platforms."
            # Extract the single file without checking GPU count
            tar --strip-components=1 -xf "${files[0]}" -C "$TMP_DIR/"
            if [ $? -eq 0 ]; then
                log_to_journal "Extracted ${files[0]} to /tmp/nvidia-fdr/platforms."
            else
                log_to_journal "Failed to extract ${files[0]}."
                exit 1
            fi
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

# Step 3: Determine platform and GPU count
get_gpu_count() {
    output=$(busctl get-property xyz.openbmc_project.FruDevice /xyz/openbmc_project/FruDevice/PG548 xyz.openbmc_project.FruDevice PRODUCT_PRODUCT_NAME 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_to_journal "NO FRU found"
        exit 1
    fi

    log_to_journal "Platform query output: $output"

    gpu_count=$(echo "$output" | grep "GPU" | sed 's/.*[^0-9]\([0-9]\)GPU.*/\1/')
    if [ -z "$gpu_count" ]; then
        log_to_journal "Failed to determine GPU count from the output."
        exit 1
    fi

    log_to_journal "Detected $gpu_count GPU(s)."
    echo "$gpu_count"
}

# Step 4: Select and extract the correct tar file
select_and_extract_file() {
    gpu_count="$1"
    file=$(ls "$PLATFORM_DIR"/*"${gpu_count}GPU"* 2>/dev/null | head -n 1)

    if [ -z "$file" ]; then
        log_to_journal "No matching platform file for $gpu_count GPU(s)."
        exit 1
    fi

    tar --strip-components=1 -xf "$file" -C "$TMP_DIR/"
    if [ $? -eq 0 ]; then
        log_to_journal "Extracted $file to /tmp/nvidia-fdr/platforms."
        log_to_journal "GPU count: $gpu_count"
    else
        log_to_journal "Failed to extract $file."
        exit 1
    fi
}

# Step 5: Wait for HMC Ready
check_hmcready() {
    CMD="busctl get-property xyz.openbmc_project.State.ConfigurableStateManager /xyz/openbmc_project/state/configurableStateManager/Manager xyz.openbmc_project.State.FeatureReady State"
    DESIRED_OUTPUT='s "xyz.openbmc_project.State.FeatureReady.States.Enabled"'
    INTERVAL=10
    MAX_DURATION=$((5 * 60))
    START_TIME=$(date +%s)

    while true; do
        OUTPUT=$(eval "$CMD")
        echo "Command output: $OUTPUT"
        echo "Comparing: '$OUTPUT' vs '$DESIRED_OUTPUT'"

        if [[ "$OUTPUT" == "$DESIRED_OUTPUT" ]]; then
            echo "Desired state reached: $OUTPUT"
            return 0
        fi

        CURRENT_TIME=$(date +%s)
        ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
        echo "Elapsed time: $ELAPSED_TIME seconds"

        if [[ $ELAPSED_TIME -ge $MAX_DURATION ]]; then
            echo "Timeout reached after $MAX_DURATION seconds. Desired state not achieved."
	    echo "Current state $OUTPUT"
            return 0
        fi

        echo "Sleeping for $INTERVAL seconds..."
        sleep $INTERVAL
    done
}


# Main script execution
main() {
    clean_tmp_directory              # Step 1: Prepare the temporary directory
    check_and_extract_single_file    # Step 2: Handle single file case or continue
    gpu_count=$(get_gpu_count)       # Step 3: Determine GPU count
    select_and_extract_file "$gpu_count"  # Step 4: Extract based on GPU count
    check_hmcready                   # Step 4: Wait till hmcReady
}

main

