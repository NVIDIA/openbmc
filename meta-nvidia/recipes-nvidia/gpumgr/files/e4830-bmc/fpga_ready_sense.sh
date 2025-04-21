#!/bin/sh
# sense fpga_ready status and start relevant systemd target
echo "fpga_ready is set"

systemctl start nvidia-fpga-ready.target

