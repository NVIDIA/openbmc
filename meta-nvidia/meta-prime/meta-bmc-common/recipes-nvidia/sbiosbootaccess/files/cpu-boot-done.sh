#!/bin/bash

# Enable host interface
/usr/bin/control-bios-host-interface.sh boot-done 

# Rescan FRUs
/usr/bin/rescan-frus.sh

exit 0
