#!/bin/bash

# Action 1 - Get the CX7 list
cx7_list=$(busctl tree xyz.openbmc_project.EntityManager | grep '/xyz/openbmc_project/inventory/system/networkadapter')

# Extracting the individual CX7 entries
cx7_entries=$(echo "$cx7_list" | awk '{print $NF}' | grep 'CX7')

# Action 2 - Loop through each CX7 entry
for cx7_entry in $cx7_entries; do

    # Get the state sensor for the current CX7 entry
    state_sensor=$(busctl tree xyz.openbmc_project.PLDM | grep "/xyz/openbmc_project/state.*$(basename "$cx7_entry")")

    # Check if state_sensor is empty, exit loop if so
    if [ -z "$state_sensor" ]; then
        continue
    fi

    # Extracting the state sensor path
    state_sensor_path=$(echo "$state_sensor" | awk '{print $NF}')

    # Action 3 - Get the Associations property
    associations=$(busctl get-property xyz.openbmc_project.PLDM $state_sensor_path xyz.openbmc_project.Association.Definitions Associations)

    # Extracting the number of entries and the property value
    num_entries=$(echo "$associations" | awk '{print $2}')
    property_value=$(echo "$associations" | sed -n 's/^a(sss) [0-9]* "\(.*\)"$/\1/p' | sed 's/"//g')

    # Incrementing the number of entries
    new_num_entries=$((num_entries + 1))

    # Action 4 - Set the Associations property with the new values
    busctl set-property xyz.openbmc_project.PLDM $state_sensor_path xyz.openbmc_project.Association.Definitions Associations 'a(sss)' $new_num_entries $property_value "parent_device" "all_states" "$cx7_entry"
done
