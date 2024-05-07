#!/bin/bash
#
# This script is used to get the MAC Address from FRU Inventory information

ETHERNET_INTERFACE="eth0"
ETHERNET_NCSI="eth0"
ENV_ETH="eth2addr"
ENV_MAC_ADDR=$(fw_printenv | grep $ENV_ETH)

# Inherit Logging
source /etc/default/nvidia_event_logging.sh

# Read FRU Board Custom Field 1 to get the MAC address
source /etc/default/fru.conf
echo "MAC_ADDR is ${MAC_ADDR}"

# Check if BMC MAC address is exported
if [ -z "${MAC_ADDR}" ]; then
    phosphor_log "ERROR: No BMC MAC address is detected from FRU Inventory information" $sevErr
	# Return 1 so that systemd knows the service failed to start
	exit 1
fi

echo "Found MAC Address in FRU = $MAC_ADDR"

# Check if BMC MAC address is exported
if [[ $ENV_MAC_ADDR =~ $MAC_ADDR ]]; then
	echo "Notice: BMC MAC address already exists"
fi

# Validate MAC address against regex
if [[ $MAC_ADDR =~ ^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$ ]]; then
        echo "MAC Address $MAC_ADDR is valid"
else
        phosphor_log "MAC Address $MAC_ADDR is invalid" $sevWarn
        exit 1
fi

# Request to update the MAC address
fw_setenv ${ENV_ETH} "${MAC_ADDR}"

if fw_setenv ${ENV_ETH} "${MAC_ADDR}";
then
    echo "WARNING: Setting ethaddr gives exit code $(echo "$?")"
fi

# Request to restart the service
ifconfig ${ETHERNET_INTERFACE} down
if ! ifconfig ${ETHERNET_INTERFACE} hw ether "${MAC_ADDR}";
then
    phosphor_log "ERROR: Can not update MAC ADDR to ${ETHERNET_INTERFACE}" $sevErr
	exit 1
fi
ifconfig ${ETHERNET_INTERFACE} up

echo "Successfully updated the MAC address ${MAC_ADDR} to ${ENV_ETH} and ${ETHERNET_INTERFACE}"
