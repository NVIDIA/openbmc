#!/bin/sh

if [ "$1" == "on" ]
then
  echo "Write Protect On"
  #BMC
  gpioset -m exit `gpiofind "GLOBAL_WP_BMC-O"`=1
  #HMC
  gpioset -m exit `gpiofind "GLOBAL_WP_HMC-O"`=1
  #CPU
  gpioset -m exit `gpiofind "WP_HW_EXT_CTRL_L-O"`=0
  gpioset -m exit `gpiofind "SEC_WP_HW_EXT_CTRL_L-O"`=0
  #BMC FRU EEPROM
  gpioset -m exit `gpiofind "BMC_FRU_WP-O"`=1
elif [ "$1" == "off" ]
then
  echo "Write Protect Off"
  #BMC
  gpioset -m exit `gpiofind "GLOBAL_WP_BMC-O"`=0
  #HMC
  gpioset -m exit `gpiofind "GLOBAL_WP_HMC-O"`=0
  #CPU
  gpioset -m exit `gpiofind "WP_HW_EXT_CTRL_L-O"`=1
  gpioset -m exit `gpiofind "SEC_WP_HW_EXT_CTRL_L-O"`=1
  #BMC FRU EEPROM
  gpioset -m exit `gpiofind "BMC_FRU_WP-O"`=0
else
  echo "$0 has no $1 definition."
fi
