#!/bin/bash

#Host Iface users created by BMC will be added
#under "redfish-hostiface" group
host_iface_group="redfish-hostiface"
group_file_path="/etc/group"

host_iface_users=$(echo $(grep $host_iface_group $group_file_path) | awk -F":" '{print $NF}')
for user in ${host_iface_users//,/ }
do
    #Delete the Host Iface User
    echo "Deleting HI user $user"
    busctl call xyz.openbmc_project.User.Manager /xyz/openbmc_project/user/$user xyz.openbmc_project.Object.Delete Delete
done

#Check the EnableAfterReset DBus property status
#And accordingly set/reset CredentialBootstrap DBus property
enableAfterReset=`busctl get-property xyz.openbmc_project.BIOSConfigManager /xyz/openbmc_project/bios_config/manager xyz.openbmc_project.BIOSConfig.Manager EnableAfterReset | cut -d ' ' -f 2`

if ($enableAfterReset -eq 'true')
then
    #Set the CredentialBootstrap DBus property to true
    busctl set-property xyz.openbmc_project.BIOSConfigManager /xyz/openbmc_project/bios_config/manager xyz.openbmc_project.BIOSConfig.Manager CredentialBootstrap b true
else
    #Set the CredentialBootstrap DBus property to false
    busctl set-property xyz.openbmc_project.BIOSConfigManager /xyz/openbmc_project/bios_config/manager xyz.openbmc_project.BIOSConfig.Manager CredentialBootstrap b false
fi
