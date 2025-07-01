#!/bin/sh

findmtd() {
    m=$(grep -xl "$1" /sys/class/mtd/*/name 2>/dev/null | head -n1)
    m=${m%/name}
    m=${m##*/}
    echo "$m"
}

wait_for_pciechip_mtd_release() {
    mtddev=$(findmtd "pciechip_config")
    [ -z "$mtddev" ] && return 0  # Not present? Nothing to wait for.

    devpath="/dev/$mtddev"
    for i in {1..10}; do
        if ! lsof "$devpath" >/dev/null 2>&1; then
            return 0
        fi
        echo "Waiting for $devpath to be released..."
        sleep 1
    done
    echo "Timeout waiting for $devpath to close"
    return 1
}

FILE_PATH=/var/pciechip/file.bin
mkdir -p /var/pciechip/

if { [ -n "$1" ] && [ "$1" -eq 1 ]; } || [ ! -e "$FILE_PATH" ]; then
    m=$(findmtd "pciechip_config")
    if [ -n "$m" ]; then
        dd if="/dev/$m" of="$FILE_PATH" bs=4K
    else
        echo "Unable to find MTD partition for pciechip_config"
    fi
fi

wait_for_pciechip_mtd_release

echo "1e630000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/unbind
udevadm settle
sleep 1

echo "1e630000.spiraw" > /sys/bus/platform/drivers/fmc_spi/bind
udevadm settle
sleep 1

set-spi-wp -d /dev/spidev2.0 -a assert

gpioset $(gpiofind "BRDG_MUX_SEL_IOX")=1
gpioset $(gpiofind "MUX_SEL_FPGA_BRDG_1V8")=0

#execute below only if it is fw update which will
#have 3 parameters and the first one is equal to 1
if [ -n "$1" ] && [ "$1" -eq 1 ] && [ -n "$2" ] && [ -n "$3" ]; then
    expected_md5sum="$2"
    compare_size="$3"
    if [ "$compare_size" -lt 1048576 ]; then
        dd if="$FILE_PATH" of="$FILE_PATH.tmp" bs=1 count="$compare_size"
        rm "$FILE_PATH"
        mv "$FILE_PATH.tmp" "$FILE_PATH"
        if [ "$(md5sum "$FILE_PATH" | awk '{print $1}')" != "$expected_md5sum" ]; then
            echo "Image verification failed!!!"
            er=1
        fi
    else
        echo "Failed to read the image file!!!"
        er=1
    fi
else
    systemctl restart com.Nvidia.MTD.Updater.pciechip.service
fi

exit $er

