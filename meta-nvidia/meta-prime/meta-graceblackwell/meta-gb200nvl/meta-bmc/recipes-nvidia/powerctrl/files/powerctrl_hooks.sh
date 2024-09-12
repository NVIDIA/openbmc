#!/bin/bash

#######################################
# Check if manual control is enabled for PCI_MUX_SEL-O
#
# Manual control is never supported.
#
# ARGUMENTS:
#   None
# RETURN:
#   1 - Manual control is disabled (always)
is_manual_pci_mux_sel_control_enabled_hook()
{
    echo "Manual control of PCI_MUX_SEL-O is not supported"
    return 1
}
