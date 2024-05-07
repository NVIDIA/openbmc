#!/bin/bash
source /etc/default/nvidia_event_logging.sh

#Contains list of "PRESENT" Module offsets
MODULE_PRSNT_ARR=()


#######################################
# Discover Number of Daisy Chained FPGAs. 
# Each module should have
# a presence pin exposed through GPIOs
#
# ARGUMENTS:
#   None
# RETURN:
#   N number of modules/FPGAs
discover_modules()
{
    err_c=0
    # N stores the index of module
    N=0
    # Count of "present" module
    prsnt_cnt=0
    
    MODULE_PRSNT_ARR=()
    for B2B_i in "${MODULE_B2B_GPIO_ARR[@]}"; do
        prsnt_gpio_cbl=$(gpioget `gpiofind ${B2B_i} 2>/dev/null`)
        if [ $? -ne 0 ]; then
                echo "Could not read presence for secondary Module $(($N + 1))."
                continue
        fi
        prsnt_gpio_c2c=$(gpioget `gpiofind ${MODULE_CLINK_GPIO_ARR[N]} 2>/dev/null`)
        if [ $? -ne 0 ]; then
                echo "Could not read presence for secondary Module $(($N + 1))."
                continue
        fi

        prsnt=$((prsnt_gpio_cbl | prsnt_gpio_c2c))

        if [ $? -eq 0 ]; then
            if [ $prsnt -eq "0" ]; then
                MODULE_PRSNT_ARR+=("${N}")
                ((prsnt_cnt++))
            else
                echo "Module $(($N + 1)) is not connected"
            fi
        fi
        ((N++));

    done

    if [ "$prsnt_cnt" -eq "0" ]; then
        echo "WARNING: No secondary modules detected on this platform!"
    fi
    
    # Write to platform variable file
    echo ${MODULE_PRSNT_ARR[@]} > $MODULE_PRSNT_FILE
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not write MODULE_PRSNT_ARR to file"
    fi

    echo ${prsnt_cnt} > $MODULE_COUNT_FILE
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not write prsnt_cnt to file"
    fi
   
    echo "$prsnt_cnt Secondary Module(s) are Present"
}

#######################################
# Discover state of every discovered 
# FPGA_READY pin
#
# ARGUMENTS:
#   None
# RETURN:
#   None
p_secondary_fpgardy_status()
{
    source /etc/default/platform_var.conf
    MODULE_PRSNT_ARR=($(cat $MODULE_PRSNT_FILE))

    if [[ "${MODULE_PRSNT_ARR[@]// /}" == "" ]]; then
        echo "Could not source PRSNT modules"
        return
    fi

    for pin_i in "${MODULE_PRSNT_ARR[@]}"; do
        pin_name=${SEC_FPGA_RDY_SIGNALS[$(($pin_i))]}
        fpgardy_status=$(gpioget `gpiofind "$pin_name"`)
        if [ $? -ne 0 ]; then
            echo "Error Reading FPGA_READY from FPGA_$pin_i. Aborting."
            continue
        fi
        if [ "$fpgardy_status" -eq 0 ]; then
            echo "FPGA_READY on Module $pin_i returns 0"
            #start any daemons for recovery?
            phosphor_log "BMC: FPGA_READY on Module $pin_i returns 0" $sevWarn
        else
            echo "FPGA_READY on Module $pin_i returns 1"
        fi
    done
}