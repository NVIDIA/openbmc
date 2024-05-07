#!/bin/bash

# Inherit Logging libraries
source /etc/default/nvidia_event_logging.sh

HIGH=1
LOW=0

set_gpio_level()
{
    gpio_line_name=$1
    gpio_level=$2

    action="set GPIO line $gpio_line_name to $gpio_level"
    gpioset -m exit `gpiofind "$gpio_line_name"`=$gpio_level
    rc=$?
    if [[ $rc -ne 0 ]]; then
        phosphor_log "Failed to $action" $sevErr
        return 1
    fi
    echo $action
    return 0

}

