do_configure:append() {
    sed -i '/pam_ipmicheck/s/^/#/'  ${WORKDIR}/pam.d/common-password
    sed -i '/pam_ipmisave/s/^/#/'  ${WORKDIR}/pam.d/common-password
}

