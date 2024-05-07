#!/bin/sh
# sense fpga_ready status and start relevant systemd target

# TODO: we need to monitor CPLD register
# for now check host power state as a proxy

On(){
    val=`i2cget -y 2 0x3c 0x2b`
    rc=$?
    echo "i2c val: [$val]"
    # GPU_BASE1_PRSNT_N && GPU_BASE_PWR_EN
    if [[ "$rc" == "0" && \
        $(( val & 0x01 )) -eq 0 && $(( val & 0x10 )) -ne 0 ]]; then
        # ready
        echo "fpga_ready is set"

        systemctl start nvidia-fpga-ready.target
    fi
}

Off(){
    # not ready
    echo "fpga_ready is not set"

    systemctl start nvidia-fpga-notready.target
}

### MAIN ###
if [ $# -eq 0 ]; then
        echo "$0 <On|Off>"
        exit 1
fi

$*
