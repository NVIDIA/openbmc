#!/bin/sh

#Set jtag mux back to CPU
gpioset `gpiofind CPLD_JTAG_MUX_SEL`=0
#The service cannot detect CPLD state changes
systemctl restart nvidia-cpld.service 
sleep 1
#Indicate jtag bus is free
systemctl stop vme-jtag-busy.target

