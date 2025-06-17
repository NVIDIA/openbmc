#!/bin/bash

PORT=$(lsof -Pan -p "$PPID" -iTCP -sTCP:ESTABLISHED 2>/dev/null | \
      awk '/TCP/ {split($9,a,"->"); split(a[1],b,":"); print b[length(b)]}' | head -n 1)

# Check if the port is 2200
if [ "$PORT" = "2200" ]; then
    exit 0
fi

exit 1