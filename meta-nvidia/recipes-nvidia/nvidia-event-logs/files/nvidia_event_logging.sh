#!/bin/bash
#
# This script is used to define the function to perform event logging in OpenBMC

phosphor_log() {
    msg=$1
    severity=$2
    busctl call xyz.openbmc_project.Logging \
            /xyz/openbmc_project/logging \
           xyz.openbmc_project.Logging.Create Create ssa{ss} \
           "$msg" "$severity" 0
}

sevErr="xyz.openbmc_project.Logging.Entry.Level.Error"
sevNot="xyz.openbmc_project.Logging.Entry.Level.Notice"
sevWarn="xyz.openbmc_project.Logging.Entry.Level.Warning"
