#!/bin/bash

print_fail()
{
  echo    "  #######    ######   ########  ###"
  echo    "  ##        ##    ##     ##     ###"
  echo    "  ##        ##    ##     ##     ###"
  echo    "  #######   ########     ##     ###"
  echo    "  ##        ##    ##     ##     ###"
  echo    "  ##        ##    ##  ########  ########"

}

print_pass()
{
    echo  " #######     ####     ######    ###### "
    echo  " ########   ######   ########  ########"
    echo  " ##    ##  ##    ##  ##     #  ##     #"
    echo  " ##    ##  ##    ##   ###       ###    "
    echo  " ########  ########    ####      ####  "
    echo  " #######   ########      ###       ### "
    echo  " ##        ##    ##  #     ##  #     ##"
    echo  " ##        ##    ##  ########  ########"
    echo  " ##        ##    ##   ######    ###### "
}


#######################################
# Confirm GPIO values against input csv
#
# This function will check all GPIOs in the input csv
# and confirm actual value versus expected value.
#
# NOTE: This function checks GPIOs based on line number
#
# ARGUMENTS:
#   arg1 - Path to gpio csv file
# RETURN:
#   0 PASS, all GPIOs set at expected value
#   1 FAIL, 1 or more GPIOs are not set at expected value
#
# CSV Columns:
# GPIO line name, GPIO Chip num, GPIO pin, Expected value
#
# Example input csv file:
#
#   FPGA_CAR_FPGA_EROT_FATAL_ERROR_L,0,88,1
#   BMC_READY-O,0,170,1
#
check_mc_gpios()
{
    status=0
    csv_file_path=$1

    # Loop through all rows in csv
    while IFS=, read -r line_name gpio_chip pin_number expected_val
    do
        # Read GPIO line value
        gpio_val=$(gpioget $gpio_chip $pin_number)

        if [[ $gpio_val == $expected_val ]]; then
            pass_fail="[PASS]"
        else
            pass_fail="[FAIL]"
            status=1
        fi
        echo "$pass_fail $line_name $gpio_chip $pin_number = $gpio_val, expected = $expected_val"
    done < $csv_file_path

    if [[ $status -ne 0 ]]; then
        print_fail
    else
        print_pass
    fi

    return $status
}
