#!/bin/bash

#
# Due to a HW bug on the HMC module, the HMC can not simply
# assert/de-assert (high/low) the [HMC_FRU_WP-O] GPIO.
# [HMC_FRU_WP-O] is a 3.3V pin. However, the HMC's FRU EEPROM
# operates on 1.8V. As a workaround, the HMC must configure
# the [HMC_FRU_WP-O] pin as either an output or an input in
# order to "drive" the signal appropriately.
# in = "high", out = "low"
#

if [ "$1" == "on" ]; then
	logger "hmc fru is protected"
	# Configure "HMC_FRU_WP-O GPIO as input
	gpioget $(gpiofind HMC_FRU_WP-O)
fi

if [ "$1" == "off" ]; then
	logger "hmc fru isn't protected"
	# Configure "HMC_FRU_WP-O GPIO as output
	gpioset -m exit $(gpiofind HMC_FRU_WP-O)=0
fi
