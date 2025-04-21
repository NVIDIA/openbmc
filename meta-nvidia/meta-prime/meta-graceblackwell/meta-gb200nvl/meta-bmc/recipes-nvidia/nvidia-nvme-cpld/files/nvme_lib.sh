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
