#!/bin/bash
#!/bin/sh
 
if [ -f "link_logs" ]; then
    echo "Found unknown logs directory, removing...."
    rm -rf link_logs
fi
 
for i in 0x33 0x44 0x45 0x46 0x47 0x48 0x49 0x0B; do
    echo "Dumping $i"
    ./aries-link-dump-obmc-ast2600 3 $i
    mv link_logs link_logs_${i}
done
