#!/bin/bash

PORT=$(lsof -Pan -p "$PPID" -iTCP -sTCP:ESTABLISHED 2>/dev/null | \
      awk '/TCP/ {split($9,a,"->"); split(a[1],b,":"); print b[length(b)]}' | head -n 1)

# Check if the port is 2200, 2201, 2202, or 2203
# CPU0 UART0 = /dev/ttyS2, port 2200
# CPU0 UART1 = /dev/ttyUSB1, port 2201
# CPU1 UART0 = /dev/ttyUSB4, port 2202
# CPU1 UART1 = /dev/ttyUSB5, port 2203
if [[ "$PORT" == "2200" || "$PORT" == "2201" || "$PORT" == "2202" || "$PORT" == "2203" ]]; then
    exit 0
fi

exit 1
