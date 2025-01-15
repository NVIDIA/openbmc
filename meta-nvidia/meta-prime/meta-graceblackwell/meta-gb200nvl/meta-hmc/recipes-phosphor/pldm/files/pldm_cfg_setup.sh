#!/bin/bash

src_fw_cfg_file="$1"
dst_fw_cfg_file="/usr/share/pldm/fw_update_config.json"

# Check if the command line argument is not empty
if [ -z "$src_fw_cfg_file" ]; then
  echo "ERROR: Empty pldm setup cfg file name !!!"
  exit 1
fi

# Check if the source file exists
if [ -f "$src_fw_cfg_file" ]; then
	echo "Copying pldm setup config file: $src_fw_cfg_file"

	if cmp -s "$src_fw_cfg_file" "$dst_fw_cfg_file"; then
		echo "No change in platform config file."
		exit 0
	else
		# Copy platform specific pldm config setup to /usr/share
		cp "$src_fw_cfg_file" "$dst_fw_cfg_file"

		# Check if the copy was successful
		if [ $? -eq 0 ]; then
			echo "Pldm setup config file copy done."
			# Restart pldmd with appropriate platform config
			systemctl restart pldmd.service
			exit 0
		else
			echo "ERROR: Failed to pldm setup config copy file !!!"
		fi
	fi
else
	echo "ERROR: Pldm setup config file does not exist !!!"
fi
exit 1
