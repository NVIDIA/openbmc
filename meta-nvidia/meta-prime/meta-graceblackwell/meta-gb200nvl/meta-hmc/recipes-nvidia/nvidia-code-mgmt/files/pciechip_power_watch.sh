#!/bin/sh
set -e

LOCKFILE=/run/pciechip.lock
STATEFILE=/run/pciechip.last
TRIGGER=/run/pciechip.trigger

echo "Starting pciechip guard loop..."

# Ensure FIFO exists
if [ ! -p "$TRIGGER" ]; then
    echo "Creating FIFO: $TRIGGER"
    rm -f "$TRIGGER"
    mkfifo "$TRIGGER"
fi

while true; do
    echo "Waiting for trigger..."
    if read -r new_state < "$TRIGGER"; then
        echo "Received trigger: $new_state"

        # Deduplicate
        if [ -f "$STATEFILE" ] && [ "$(cat "$STATEFILE")" = "$new_state" ]; then
            echo "State unchanged ($new_state), skipping"
            continue
        fi
        echo "$new_state" > "$STATEFILE"

        (
            flock -n 200 || {
                echo "Another instance is running. Skipping."
                exit 0
            }

            echo "Handling power state: $new_state"

            case "$new_state" in
                On)
                    /usr/bin/setup_pciechip.sh 0
                    /usr/bin/cleanup_pciechip.sh 0
                    ;;
                Off)
                    # Optional: add off-handling logic here if needed
                    echo "Power state is Off, no action taken"
                    ;;
                *)
                    echo "Unknown state: $new_state"
                    ;;
            esac
        ) 200>"$LOCKFILE"
    fi
done
