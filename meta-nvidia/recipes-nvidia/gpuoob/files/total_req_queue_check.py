#!/usr/bin/python3
from datetime import datetime
import sys
import re
from collections import deque				

properties_file = sys.argv[1]
import json
with open(properties_file, "r") as f:
    properties_dict = json.load(f)

manifest_file = sys.argv[2]
with open(manifest_file, "r") as f:
    devices_counts = json.load(f)

fpga_target_dev_count = 0;
gpu_target_dev_count = 0;
nvswitch_target_dev_count = 0;
for property in properties_dict["properties"]:
    try:
        dev_name = property["name"].split(".")[0]
        if dev_name == "fpga":
            dev_count = 1
        else:
            dev_count = devices_counts["fpga"][0][dev_name]
        target_dev = property["accessor"].split(".")[0]

        l_count = 1
        for i in range(dev_count):
            if dev_name != target_dev:
                l_count = dev_count # case where each dev req is mapping to same opcode and lookup in smbpbi layer
        if target_dev == "gpu":
            if "pages" in property:
                gpu_target_dev_count += (property["pages"] * l_count)
            else:
                gpu_target_dev_count += (1 * l_count)
        if target_dev == "fpga":
            if "pages" in property:
                fpga_target_dev_count += (property["pages"] * l_count)
            else:
                fpga_target_dev_count += (1 * l_count)
        if target_dev == "nvswitch":
            if "pages" in property:
                nvswitch_target_dev_count += (property["pages"] * l_count)
            else:
                nvswitch_target_dev_count += (1 * l_count)
    except:
        continue

try:
    print(f'{fpga_target_dev_count + gpu_target_dev_count * devices_counts["fpga"][0]["gpu"] + nvswitch_target_dev_count * devices_counts["fpga"][0]["nvswitch"]} {max(gpu_target_dev_count, fpga_target_dev_count, nvswitch_target_dev_count)}')
except:
    print(f'0 0')

