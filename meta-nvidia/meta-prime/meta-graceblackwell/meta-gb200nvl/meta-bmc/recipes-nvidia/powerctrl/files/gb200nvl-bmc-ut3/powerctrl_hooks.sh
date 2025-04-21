#!/bin/bash

#######################################
# Check if manual control is enabled for PCI_MUX_SEL-O
#
# Manual control is enabled/disabled via
# MANUAL_PCI_MUX_SEL_FILE (system_state_files.sh)
#
# ARGUMENTS:
#   None
# RETURN:
#   0 - Manual control is enabled
#   1 - Manual control is disabled
is_manual_pci_mux_sel_control_enabled_hook()
{
    if [[ -f "$MANUAL_PCI_MUX_SEL_FILE" ]]; then
        echo "Manual control of PCI_MUX_SEL-O is Enabled"
        return 0
    fi
    echo "Manual control of PCI_MUX_SEL-O is Disabled"
    return 1
}
