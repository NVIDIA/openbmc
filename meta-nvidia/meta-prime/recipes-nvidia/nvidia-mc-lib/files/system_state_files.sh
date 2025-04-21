#!/bin/bash

#
# STATE_FILE_PATH: The path where the state files are stored
#
STATE_FILE_PATH="/run/bmc-state"

if [ ! -d "$STATE_FILE_PATH" ]; then
    mkdir $STATE_FILE_PATH
fi

#
# RUN_POWER_PG_FILE
# Purpose: 	Stores the value of the RUN POWER PG GPIO
# Scope:	Always exists, cating the file will provide GPIO state
#
RUN_POWER_PG_FILE="$STATE_FILE_PATH/RUN_POWER_PG"

#
# STANDBY_POWER_PG_FILE
# Purpose: 	Stores the value of the STANDBY POWER PG GPIO
# Scope:	Always exists, cating the file will provide GPIO state
#
STANDBY_POWER_PG_FILE="$STATE_FILE_PATH/STANDBY_POWER_PG"

#
# MCTP_FIRST_TIME_INIT_FILE
# Purpose: 	File set the first time MCTP comes up
#		Used to detect the first MCTP enumeration attempt
#		(needed in the event the BMC was rebooted with the host powered on)
# Scope:	File persists the entire time the BMC up after
#		creation on first MCTP startup
#
MCTP_FIRST_TIME_INIT_FILE="$STATE_FILE_PATH/MCTP_FIRST_TIME_INIT"

#
#
# GPU_MANAGER_FIRST_TIME_INIT_FILE
# Purpose: 	File set the first time gpu manager comes up
#		Used to detect the first gpu manager run
#		(needed in the event the BMC was rebooted with the host powered on)
# Scope:	File persists the entire time the BMC up after
#		creation on first gpu manager startup
#
GPU_MANAGER_FIRST_TIME_INIT_FILE="$STATE_FILE_PATH/GPU_MANAGER_FIRST_TIME_INIT"

#
# CPU_BOOT_DONE_FILE
# Purpose:	File set when we receive a CPU boot done signal from the FPGA
# Scope:	Created when the host boots, cleared on the next host power on attempt
#
CPU_BOOT_COMPLETE_FILE="$STATE_FILE_PATH/CPU_BOOT_COMPLETE"

#
# CPU_BOOT_TIMEOUT_FILE
# Purpose:	File set if we do not receive a host boot signal in 30 seconds
# Scope:	Created when the host boot times out, cleared on the next host power on attempt
#
CPU_BOOT_TIMEOUT_FILE="$STATE_FILE_PATH/CPU_BOOT_TIMEOUT"

#
# PERST_SIGNALLED_FILE
# Purpose:	File set when a PERST signal is received
# Scope:	
#
PERST_SIGNALLED_FILE="$STATE_FILE_PATH/PERST_SIGNALLED"

#
# PERST_FAILURE_FILE
# Purpose:	File set when a PERST signal is not received within 60 sec of host power on
# Scope:	
#
PERST_FAILURE_FILE="$STATE_FILE_PATH/PERST_FAILURE"

#
# PCIE_INIT_GOOD_FILE
# Purpose:	File set when PCIE has been initialized and is in a good state (ready for MCTP/SMBPBI)
# Scope:	
#
PCIE_INIT_GOOD_FILE="$STATE_FILE_PATH/PCIE_INIT_GOOD"

#
# SHDN_OK_FILE
# Purpose:	
# Scope:	
#
SHDN_OK_FILE="$STATE_FILE_PATH/SHDN_OK"

#
# SYS_DISCOVERY_FILE
# Purpose:	
# Scope:	
#
SYS_DISCOVERY_FILE="$STATE_FILE_PATH/CHASSIS_IS_PWR_ON"

#
# HOST_ID_FILE
# Purpose:	host identity information discovered on BMC boot
# Scope:	
#
HOST_ID_FILE="$STATE_FILE_PATH/HOST_ID"

#
# MANUAL_PCI_MUX_SEL_FILE
# Purpose:	Allow manual control of GPIO PCI_MUX_SEL-O
# Scope:
#
MANUAL_PCI_MUX_SEL_FILE="$STATE_FILE_PATH/MANUAL_PCI_MUX_SEL"