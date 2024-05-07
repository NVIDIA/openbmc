FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
    cat >> ${D}${sysconfdir}/fstab <<EOF

/dev/mtdblock7      /var/lib/logging/   jffs2      defaults,sync,nofail,x-systemd.device-timeout=600         0  0
none                /tmp                         tmpfs      rw,nosuid,nodev,nr_inodes=409600,size=280M    0  0
tmpfs               /tmp/images                  tmpfs      defaults,size=200M    0  0

EOF
    ISPROD="${@bb.utils.contains("BUILD_TYPE", "prod", "1", "0", d)}"
    ISDEBUG="${@bb.utils.contains("BUILD_TYPE", "debug", "1", "0", d)}"
    if [ "${ISPROD}" = "1" ] ||  [ "${ISDEBUG}" = "1" ]; then
        sed -i -r 's#(/\s.*defaults)\s#\1,ro #' ${D}${sysconfdir}/fstab
    fi
}
