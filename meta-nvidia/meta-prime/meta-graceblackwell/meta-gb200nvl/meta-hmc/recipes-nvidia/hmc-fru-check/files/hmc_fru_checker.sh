#!/bin/bash
# Inherit Logging libraries
source /etc/default/nvidia_event_logging.sh

# Constants
EEPROM_PATH="/sys/bus/i2c/devices/3-0057/eeprom"
FRU_DIR="/etc/fru"
FRU_FILE="${FRU_DIR}/baseboard.fru.bin"
MAX_RETRIES=10
SLEEP_BETWEEN_RETRIES=0.1  # 100ms

TEMP_FILE=$(mktemp)
# Function to read eeprom with retries
read_eeprom() {
    local success=false
    local retry=0

    while [ $retry -lt $MAX_RETRIES ] && [ "$success" = false ]; do
        if dd if=$EEPROM_PATH of=$TEMP_FILE bs=1 count=512 2>/dev/null; then
            # Verify the read was successful by checking file size
            if [ -s "$TEMP_FILE" ]; then
                success=true
                break
            fi
        fi
        retry=$((retry + 1))
        echo "Retry $retry reading EEPROM..."
        sleep $SLEEP_BETWEEN_RETRIES
    done

    if [ "$success" = false ]; then
        rm -f "$TEMP_FILE"
        echo "Failed to read EEPROM after $MAX_RETRIES attempts"

        # Create empty FRU file to let FruDevice service starts
        touch "$FRU_FILE" 
        return 1
    fi

    return 0
}

# Create FRU directory if it doesn't exist
if [ ! -d "$FRU_DIR" ]; then
    mkdir -p "$FRU_DIR"
    if [ $? -ne 0 ]; then
        phosphor_log "HMC FRU read failed: Failed to create directory $FRU_DIR" $sevErr
        rm -f "$TEMP_FILE"
        exit 1
    fi
fi

if [ ! -f "/sys/bus/i2c/devices/i2c-3/3-0057/eeprom" ];then
    echo 24c02 '0x57' > /sys/bus/i2c/devices/i2c-3/new_device
fi

# Read EEPROM with retries
read_eeprom
if [ $? -ne 0 ]; then
    phosphor_log "HMC FRU read failed: Could not access FRU EEPROM" $sevErr
    rm -f "$TEMP_FILE"
    exit 1
fi

# Check if we need to update the FRU file
if [ ! -f "$FRU_FILE" ]; then
    # FRU file doesn't exist, create it
    cp "$TEMP_FILE" "$FRU_FILE"
    echo "Created new FRU file"
else
    # Compare contents
    if ! cmp -s "$TEMP_FILE" "$FRU_FILE"; then
        # Files are different, update FRU file
        cp "$TEMP_FILE" "$FRU_FILE"
        echo "Updated FRU file"
    else
        echo "FRU file is up to date"
    fi
fi

# Cleanup
rm -f "$TEMP_FILE"

exit 0
