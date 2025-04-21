#!/bin/bash

MAX_BLOCK_SIZE=8192

##############################################################################
# Convert decimal number to the hex array.
# ARGUMENTS:
#   dec_value - number to convert
#   bytes_count - number of bytes in the output hex array
# OUTPUTS:
#   Number converted to hex array with 'bytes_count' bytes.
#   Each byte is prefixed with '\x'. For example value 123,
#   with bytes_count set to 3, will be displayed as \x00\x00\x7B.
##############################################################################
dec_to_hex() {
   dec_value="$1"
   bytes_count="$2"

   if [[ -z "$bytes_count" ]]; then
      format_str="%x\n"
   else
      format_str="%0$((bytes_count*2))x\n"
   fi

   hex_val=$(printf "$format_str" "$dec_value")
   echo "$hex_val" | sed 's/../\\x&/g'
}

##############################################################################
# Verify if a dump type is correct.
# ARGUMENTS:
#   dump_type
# RETURN:
#   0 if dump type is correct, non-zero on error.
##############################################################################
verify_dump_type() {
   dump_type="$1"

   allowed_values="1 2"
   for value in $allowed_values; do
      if [[ $dump_type -eq $value ]]; then
         return 0
      fi
   done
   
   return 1
}

##############################################################################
# Initiate dump creation through the busctl command.
# ARGUMENTS:
#   dump_type - 1(bmc) or 2(system)
#   dump_sub_type - 1(FPGA) or 2(EROT)
# RETURN:
#   0 if dump init was successfull, non-zero on error.
##############################################################################
create_new_dump() {
   dump_type="$1"
   dump_sub_type="$2"

   echo "$(date) Receieved request to create new dump. Dump type: $dump_type. Dump sub type: $dump_sub_type"

   if ! verify_dump_type "$dump_type"; then 
      echo "dump_type($dump_type) must be a number between 1 and 2";
      return 1
   fi

   if ! echo "$dump_sub_type" | grep -Eq '^[0-9]+$' ; then 
      echo "dump_sub_type($dump_sub_type) must be a number between 1 and 2";
      return 1
   fi

   # Get proper busctl args
   if [[ $dump_type -eq 1 ]]; then
      busctl_args="/xyz/openbmc_project/dump/bmc xyz.openbmc_project.Dump.Create CreateDump a{sv} 0"
   elif [[ $dump_type -eq 2 ]]; then

      if [[ $dump_sub_type -eq 1 ]]; then
         diagnostic_type="FPGA"
      elif [[ $dump_sub_type -eq 2 ]]; then
         diagnostic_type="EROT"
      else
         echo "dump_sub_type($dump_sub_type) must be a number between 1 and 2";
         return 1
      fi
      busctl_args="/xyz/openbmc_project/dump/system xyz.openbmc_project.Dump.Create CreateDump a{sv} 1 DiagnosticType s $diagnostic_type"
   fi

   # Initiate dump creation
   if ! output=$(busctl call xyz.openbmc_project.Dump.Manager $busctl_args 2>&1); then
      echo "Failed to execute \"busctl call xyz.openbmc_project.Dump.Manager $busctl_args\" command. Msg: $output"
      if echo "$output" | grep -e "Call failed: The operation is not allowed" -e "Call failed: The service is temporarily unavailable"; then
         return 2 # Dump already in progress
      else
         return 1
      fi
   fi

   # put entry id in the result
   entry_id=$(basename $(echo "$output" | cut -d ' ' -f 2 | sed 's/"//g'))
   printf "$(dec_to_hex $entry_id 2)" | dd of=/sys/bus/i2c/devices/0-1045/slave-eeprom bs=1 count=2 seek=21

   echo "$(date) Dump($entry_id) creation initiated succesfully."
}

##############################################################################
# Check dump progress. Put dump size in the result, when dump is completed.
# ARGUMENTS:
#   dump_type - 1(bmc) or 2(system)
#   entry_id - entry_id
# RETURN:
#   0 if command was successfull, non-zero on error.
##############################################################################
check_dump_progress() {
   dump_type="$1"
   entry_id="$2"

   echo "$(date) Receieved request to check dump progress. Dump type: $dump_type. Entry id: $entry_id"

   if ! verify_dump_type "$dump_type"; then 
      echo "dump_type($dump_type) must be a number between 1 and 2";
      return 1
   fi

   if ! echo "$entry_id" | grep -Eq '^[0-9]+$' ; then 
      echo "entry_id($entry_id) must be a number.";
      return 1
   fi

   if [[ $dump_type -eq 1 ]]; then
      dump_type_str="bmc"
   elif [[ $dump_type -eq 2 ]]; then
      dump_type_str="system"
   fi

   entry_path="/xyz/openbmc_project/dump/$dump_type_str/entry/$entry_id"

   if ! output=$(busctl call xyz.openbmc_project.Dump.Manager $entry_path org.freedesktop.DBus.Properties Get ss xyz.openbmc_project.Common.Progress Status 2>&1); then
      echo "Failed to check dump progress. command. Msg: $output"
      return 1
   fi
   dump_status=$(echo "$output" | cut -d ' ' -f 3 | sed 's/"//g' | sed 's/.*\.//g')

   if ! output=$(busctl call xyz.openbmc_project.Dump.Manager $entry_path org.freedesktop.DBus.Properties Get ss xyz.openbmc_project.Common.Progress Progress 2>&1); then
      echo "WARNING: Failed to get dump progress percentage. command. Msg: $output"
      percentage=0
   else
      percentage=$(echo "$output" | cut -d ' ' -f 3)
   fi

   if [[ "$dump_status" == "Completed" ]]; then
      dump_size=$(busctl call xyz.openbmc_project.Dump.Manager $entry_path org.freedesktop.DBus.Properties Get ss xyz.openbmc_project.Dump.Entry Size | cut -d ' ' -f 3)
      execution_status_hex="\x01"
   else
      dump_size=0
      execution_status_hex="\x00"
   fi

   # Set 6 bytes of output data.
   # 1 byte - execution status - 0(InProgress)/1(Completed),
   # 2 byte - progress in percent,
   # 3-6 bytes - Dump size
   printf "${execution_status_hex}$(dec_to_hex $percentage 1)$(dec_to_hex $dump_size 4)" | dd of=/sys/bus/i2c/devices/0-1045/slave-eeprom bs=1 count=6 seek=21

   echo "Dump($entry_id) status: $dump_status. Percentage: ${percentage}%. Dump size: $dump_size bytes"
}

##############################################################################
# Copy different parts of a dump to the 3-104f/slave-eeprom file.
# ARGUMENTS:
#   dump_type - 1(bmc) or 2(system)
#   entry_id - entry_id
#   block_number - What part of the dump to copy. Each part(block) is a max
#                  size of 8192 bytes. 0 block_number value is a first block.
# RETURN:
#   0 if copy was successfull, non-zero on error.
##############################################################################
request_block_data() {
   dump_type="$1"
   entry_id="$2"
   block_number="$3"

   echo "$(date) Receieved request get block data. Dump type: $dump_type. Entry id: $entry_id. Block number: $block_number"

   # Verify all args
   if ! verify_dump_type "$dump_type"; then 
      echo "dump_type($dump_type) must be a number between 1 and 2";
      return 1
   fi
   if ! echo "$entry_id" | grep -Eq '^[0-9]+$' ; then 
      echo "entry_id($entry_id) must be a number.";
      return 1
   fi
   if ! echo "$block_number" | grep -Eq '^[0-9]+$' ; then 
      echo "block_number($block_number) must be a number.";
      return 1
   fi

   # Set correct dump_type_str
   if [[ $dump_type -eq 1 ]]; then
      dump_type_str="bmc"
   elif [[ $dump_type -eq 2 ]]; then
      dump_type_str="system"
   fi

   # Get dump path and dump size
   dump_name=$(ls /var/lib/logging/dumps/$dump_type_str/$entry_id)
   dump_path="/var/lib/logging/dumps/$dump_type_str/$entry_id/$dump_name"
   if [[ ! -f $dump_path ]]; then
      echo "Couldn't find dump with specified entry id: $entry_id";
      return 1
   fi
   dump_size=$(ls -l $dump_path | awk '{print $5}')
   if ! echo "$dump_size" | grep -Eq '^[0-9]+$' ; then 
      echo "Couldn't read properly dump_size. Dump size($dump_size) is not a number.";
      return 1
   fi

   # Calculate number of bytes stil left to transmit
   left_bytes_to_copy=$((dump_size-block_number*MAX_BLOCK_SIZE))

   echo "$(date) Found dump $dump_name. Dump size: $dump_size. Left bytes to copy: $left_bytes_to_copy"

   # Check if correct block_number was given.
   if [[ $left_bytes_to_copy -lt 0 ]]; then
      echo "block_number($block_number) is too big for a given file. $MAX_BLOCK_SIZE * $block_number > $dump_size";
      return 1
   fi

   # Calculate block size
   if [[ $left_bytes_to_copy -gt $MAX_BLOCK_SIZE ]]; then
      block_size=$MAX_BLOCK_SIZE
   else
      block_size=$left_bytes_to_copy
   fi

   # Save block size in the EEPROM
   if ! output=$(printf "$(dec_to_hex $block_size 4)" | dd of=/sys/bus/i2c/devices/3-104f/slave-eeprom bs=1 count=4 seek=1280 2>&1); then
      echo "Failed to write block size to eeprom file. Error msg: $output"
      return 1
   fi

   # Save block data in the EEPROM
   if ! output=$(dd if=$dump_path of=/sys/bus/i2c/devices/3-104f/slave-eeprom bs=1 count=$block_size skip=$((block_number*MAX_BLOCK_SIZE)) seek=1284 2>&1); then
      echo "Failed to write memory block to eeprom file. Error msg: $output"
      return 1
   fi

   echo "$(date) data block $block_number successfully prepared. Block size: $block_size"
}

unknown_command() {
   return 1
}

##############################################################################
# Process command base on the opcode read from '0-1045/slave-eeprom' file.
##############################################################################
process_command() {

   # Clear command execute byte and set execution status to 1
   printf '\x00\x01' | dd of=/sys/bus/i2c/devices/0-1045/slave-eeprom bs=1 count=2 seek=18

   # Copy opcode together with input arguments.
   data=$(hexdump -ve '1/1 "%02x "' /sys/bus/i2c/devices/0-1045/slave-eeprom -n 17 -s 1)
   data_array=($data)
   opcode=$((16#${data_array[0]}))

   case $opcode in
   1)
      create_new_dump $((16#${data_array[1]})) $((16#${data_array[2]}))
      ;;
   2)
      entry_id=$((16#${data_array[2]}${data_array[3]}))
      check_dump_progress $((16#${data_array[1]})) $entry_id  
      ;;
   3)
      entry_id=$((16#${data_array[2]}${data_array[3]}))
      block_number=$((16#${data_array[4]}${data_array[5]}))
      request_block_data $((16#${data_array[1]})) $entry_id $block_number
      ;;
   *)
      echo "$(date) ERROR: Unknown opcode: $opcode"
      unknown_command
   esac 
   
   # Save return code to status field
   return_code=$?
   printf "$(dec_to_hex $return_code 1)" | dd of=/sys/bus/i2c/devices/0-1045/slave-eeprom bs=1 count=1 seek=20

   # Set execution status to 0
   printf '\x00' | dd of=/sys/bus/i2c/devices/0-1045/slave-eeprom bs=1 count=1 seek=19

}

########################################## main ##########################################

echo "Checking if EEPROM files exist..."
eeprom_files_exist=false
for i in 1 2 3; do
   if [[ -f "/sys/bus/i2c/devices/3-104f/slave-eeprom" ]] && [[ -f "/sys/bus/i2c/devices/0-1045/slave-eeprom" ]]; then
      eeprom_files_exist=true
      break
   fi
   sleep 5
done
if [[ "$eeprom_files_exist" != true ]]; then
   echo "Necessary EEPROM files 3-104f/slave-eeprom and 0-1045/slave-eeprom don't exist. Exiting... "
   exit 1
fi


echo "Start processing commands. Waiting for the first command..."
while true; do
   # Check if the BMC requested command
   request_byte=$(hexdump -ve '1/1 "%02x "' /sys/bus/i2c/devices/0-1045/slave-eeprom -n 1 -s 18)
   if [[ $((16#${request_byte})) -eq 1 ]]; then
      process_command
   fi
   sleep 1
done


