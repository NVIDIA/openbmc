#!/bin/sh

findmtd() {
        m=$(grep -xl "$1" /sys/class/mtd/*/name)
        m=${m%/name}
        m=${m##*/}
        echo $m
}

er=0

mkdir -p /var/pciechip/
FILE_PATH=/var/pciechip/file.bin

#execute below only if fw update (param 1 is 1) or the file
#does not exist on the file system
#this way we do not take spi chip from the pciechip if we
#absolutely do not have to
if { [ -n "$1" ] && [ "$1" -eq 1 ]; } || [ ! -e "$FILE_PATH" ]; then
    m=$(findmtd "pciechip_config")
    if test -z "$m"
    then
        echoerr "Unable to find mtd partition for ${f##*/}."
        er=1
    else
        dd if=/dev/$m of="$FILE_PATH" bs=4K
    fi
fi

gpioset `gpiofind "BRDG_MUX_SEL_IOX"`=1
gpioset `gpiofind "MUX_SEL_FPGA_BRDG_1V8"`=0
echo "1e630000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/unbind

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

