#!/bin/bash

### MAIN ###
echo "One time RF log event service fired"

openbmclog=$(fw_printenv | grep openbmclog | sed 's/.*=//')


if [ "$openbmclog" == "factory-reset" ];
then
    busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} \
            OpenBMC.0.4.BMCFactoryReset xyz.openbmc_project.Logging.Entry.Level.Informational 2 \
            REDFISH_MESSAGE_ID OpenBMC.0.4.BMCFactoryReset \
            REDFISH_MESSAGE_ARGS ""   
    if [ $? -eq 0 ]; then
        fw_setenv openbmclog
    else    
        echo "Failed to create Redfish log for factory-reset"
    fi 
fi

if [ "$openbmclog" == "logs-reset" ];
then
    busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} \
            OpenBMC.0.4.BMCLogsErased xyz.openbmc_project.Logging.Entry.Level.Informational 2 \
            REDFISH_MESSAGE_ID OpenBMC.0.4.BMCLogsErased \
            REDFISH_MESSAGE_ARGS ""   
    if [ $? -eq 0 ]; then
        fw_setenv openbmclog
    else    
        echo "Failed to create Redfish log for logs-reset"
    fi 
fi


if [ "$openbmclog" == "dataflash-erase" ];
then
    busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging xyz.openbmc_project.Logging.Create Create ssa{ss} \
            OpenBMC.0.4.BMCRebootReason xyz.openbmc_project.Logging.Entry.Level.Informational 2 \
            REDFISH_MESSAGE_ID OpenBMC.0.4.BMCRebootReason \
            REDFISH_MESSAGE_ARGS "Dataflash erase triggered by external command"   
    if [ $? -eq 0 ]; then
        fw_setenv openbmclog
    else    
        echo "Failed to create Redfish log for dataflash-erase"
    fi 
fi
