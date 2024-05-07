# Force the mctp-demux to be used until machine is ready to use in-kernel MCTP
PACKAGECONFIG:append = " transport-mctp-demux oem-ibm"

EXTRA_OEMESON += " \
        -Dsoftoff=enabled \
        -Dsoftoff-timeout-seconds=2700 \
        "

#5 second timeout defined inside PLDM has seen issues during reset reload
#so increasing that to 10 seconds here.IBMs custom firmware stack can tolerate
#PLDM timeouts of up to 20 seconds, so using timeout value of 10 seconds is safe.
EXTRA_OEMESON += " \
         -Ddbus-timeout-value=10 \
        "

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'oem-ibm', \
    'pldm-create-phyp-nvram.service \
     pldm-create-phyp-nvram-cksum.service \
    ', '', d)}"

# Install pldmSoftPowerOff.service in correct targets
pkg_postinst:${PN} () {

    mkdir -p $D$systemd_system_unitdir/obmc-host-shutdown@0.target.wants
    LINK="$D$systemd_system_unitdir/obmc-host-shutdown@0.target.wants/pldmSoftPowerOff.service"
    TARGET="../pldmSoftPowerOff.service"
    ln -s $TARGET $LINK

    mkdir -p $D$systemd_system_unitdir/obmc-host-warm-reboot@0.target.wants
    LINK="$D$systemd_system_unitdir/obmc-host-warm-reboot@0.target.wants/pldmSoftPowerOff.service"
    TARGET="../pldmSoftPowerOff.service"
    ln -s $TARGET $LINK
}

pkg_prerm:${PN} () {

    LINK="$D$systemd_system_unitdir/obmc-host-shutdown@0.target.wants/pldmSoftPowerOff.service"
    rm $LINK

    LINK="$D$systemd_system_unitdir/obmc-host-warm-reboot@0.target.wants/pldmSoftPowerOff.service"
    rm $LINK
}
