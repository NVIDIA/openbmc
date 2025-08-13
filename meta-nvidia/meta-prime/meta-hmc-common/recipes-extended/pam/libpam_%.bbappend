do_configure:append() {
    sed -i '/pam_ipmicheck/s/^/#/'  ${UNPACKDIR}/pam.d/common-password
    sed -i '/pam_ipmisave/s/^/#/'  ${UNPACKDIR}/pam.d/common-password
}

