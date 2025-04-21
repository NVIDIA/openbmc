#!/bin/bash

# Inherit Logging
source /etc/default/nvidia_event_logging.sh


overtemp(){
    phosphor_log "GPIO Alert: Overtemp detected - $1. Performing host shutdown." $sevErr
}

fault(){
    phosphor_log "GPIO Alert: power fault detected - $1. See HMC event log." $sevErr
}

fan-fail(){
    phosphor_log "GPIO Alert: fan failure detected - $1." $sevErr
}


$*
