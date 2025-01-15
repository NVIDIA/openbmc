FILESEXTRAPATHS:prepend := "${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', '${THISDIR}/${BPN}:', '', d)}"

do_install:append() {
    cat >> ${D}${sysconfdir}/fstab <<EOF

/tmp/coredump_tmp    /var/lib/systemd/coredump  none  bind  0  0 

EOF
}