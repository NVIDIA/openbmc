nvme_cpld_bind() {

    nvmebus=$1
    nvme7baddr=$2
    rc=0

    if [ ! -d /sys/bus/i2c/devices/i2c-$nvmebus/$nvmebus-00$nvme7baddr/channel-0 ]; then
        echo $nvmebus-00$nvme7baddr > /sys/bus/i2c/drivers/pca954x/bind
        rc=$?
    fi

    if [ $rc -eq 0 ]; then
        echo "I2C MUX $nvmebus-00$nvme7baddr has been bound to /sys/bus/i2c/drivers/pca954x"
    else
        echo "Unable to bind I2C MUX $nvmebus-00$nvme7baddr to pca9546 driver"
    fi
}

nvme_cpld_unbind() {

    nvmebus=$1
    nvme7baddr=$2
    force_unbind=$3

    if [ -d /sys/bus/i2c/devices/$nvmebus-00$nvme7baddr ]; then
        if [ ! -d /sys/bus/i2c/devices/$nvmebus-00$nvme7baddr/channel-0 ] || [ "$force_unbind" == "force" ] ; then
            # The NVME CPLD on the backplane is powered by RUN_POWER, which
            # means the previous MUX probe could fail if bmc booted when host-off.
            # In this case we have to rebind the device to probe the MUX again
            # when host-on.
            if [ -d /sys/bus/i2c/drivers/pca954x/$nvmebus-00$nvme7baddr ]; then
                echo "Unbinding I2C MUX $nvmebus-00$nvme7baddr ..."
                echo $nvmebus-00$nvme7baddr > /sys/bus/i2c/drivers/pca954x/unbind
            fi
            return 0
        else
            echo "I2C MUX $nvmebus-00$nvme7baddr exists. Stop unbind."
            return 1
        fi
    fi

    return 0
}

nvme_eeprom_probe() {
    nvmebus=$1
    nvme7baddr=$2

    if [ -d /sys/bus/i2c/devices/i2c-$nvmebus ]; then
        if [ ! -d /sys/bus/i2c/devices/i2c-$nvmebus/$nvmebus-00$nvme7baddr  ]; then
            echo 24c02 0x$nvme7baddr > /sys/bus/i2c/devices/i2c-$nvmebus/new_device
        fi
    fi
}

nvme_eeprom_remove() {
    nvmebus=$1
    nvme7baddr=$2

    if [ -d /sys/bus/i2c/devices/i2c-$nvmebus/$nvmebus-00$nvme7baddr  ]; then
        echo 0x$nvme7baddr > /sys/bus/i2c/devices/i2c-$nvmebus/delete_device
    fi
}

nvme_create_gb200_eeproms() {
    # i2c8@0x53: M.2 primary/boot drive.
    # i2c[40-43]@0x53: E1.S slot 0-3.
    # i2c[44-47]@0x53: E1.S slot 4-7.
    # i2c49@0x53: M.2 secondary drive.

    for i in 8 40 41 42 43 44 45 46 47 49; do
       nvme_eeprom_probe $i 53
    done
}

nvme_remove_gb200_eeproms() {
    # i2c8@0x53: M.2 primary/boot drive.
    # i2c[40-43]@0x53: E1.S slot 0-3.
    # i2c[44-47]@0x53: E1.S slot 4-7.
    # i2c49@0x53: M.2 secondary drive.

    for i in 8 40 41 42 43 44 45 46 47 49; do
       nvme_eeprom_remove $i 53
    done
}
