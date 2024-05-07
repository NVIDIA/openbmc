#!/bin/sh
# sense fpga_ready status and start relevant systemd target

# TODO: we need to monitor CPLD register
# for now check host power state as a proxy

On()
{
    # after power on - wait for baseboard to be powered up
    # this is mainly required for FPGA to be ready and refclk - which
    # is sourced from cpu clk - to be stabilised
    sleep 90

    val=`i2cget -y 2 0x3c 0x2b`
    rc=$?
    echo "i2c val: [$val]"
    # GPU_BASE1_PRSNT_N && GPU_BASE_PWR_EN && GPU_BASE1_CPLD_READY
    if [[ "$rc" == "0" && \
    $(( val & 0x01 )) -eq 0 && $(( val & 0x10 )) -ne 0  && \
    $(( val & 0x04 )) -ne 0 ]]; then
        # ready
        echo "fpga_ready is set"

        # MCTP controller is being reset by the PERST pin
        # coming from CPU for vga connection. Wait here
        # to get past the point where CPU drives the PERST
        # before loading mctp drivers
        sleep 30

        # deassert perst when fpga/host is up
        devmem 0x1e6e2044 w 0x40000
        sleep 2

        ### Start MCTP drivers ###
        echo "1e6f9000.mctp" > /sys/bus/platform/drivers/aspeed-mctp/bind | true
        sleep 1;systemctl start mctp-demux;sleep 1;

        sleep 2
        systemctl start pldmd
        sleep 1

        systemctl start nvidia-fpga-ready.target
    fi
}

Off()
{
    # not ready
    echo "fpga_ready is not set"

    systemctl stop pldmd;systemctl stop mctp-pcie-ctrl;systemctl stop mctp-pcie-demux.socket;systemctl stop mctp-pcie-demux.service;
    while [ ! -z "`systemctl list-units --type service --state running |grep mctp-pcie-demux`" ];do sleep 2;done

    ### Stop MCTP drivers ####
    echo "1e6f9000.mctp" > /sys/bus/platform/drivers/aspeed-mctp/unbind | true
    sleep 2

    # assert perst when fpga/host is down
    devmem 0x1e6e2040 w 0x40000

    sleep 2

    systemctl start nvidia-fpga-notready.target

}

### MAIN ###
if [ $# -eq 0 ]; then
        echo "$0 <On|Off>"
        exit 1
fi

$*

